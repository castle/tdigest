require 'rbtree'
require 'tdigest/centroid'

module TDigest
  class TDigest
    VERBOSE_ENCODING = 1
    SMALL_ENCODING   = 2

    attr_accessor :centroids
    def initialize(delta = 0.01, k = 25, cx = 1.1)
      @delta = delta
      @k = k
      @cx = cx
      @centroids = RBTree.new
      @nreset = 0
      reset!
    end

    def +(other)
      # Uses delta, k and cx from the caller
      t = self.class.new(@delta, @k, @cx)
      data = self.centroids.values + other.centroids.values
      while data.length > 0
        t.push_centroid(data.delete_at(rand(data.length)))
      end
      t.compress!
      t
    end

    def merge!(other)
      # Uses delta, k and cx from the caller
      t = self + other
      @centroids = t.centroids
      compress!
    end

    def as_bytes
      # compression as defined by Java implementation
      size = @centroids.size
      output = [VERBOSE_ENCODING, compression, size]
      output += @centroids.map { |_, c| c.mean }
      output += @centroids.map { |_, c| c.n }
      output.pack("LdLd#{size}L#{size}")
    end

    def as_small_bytes
      size = @centroids.size
      output = [SMALL_ENCODING, compression, size]
      x = 0
      # delta encoding allows saving 4-bytes floats
      mean_arr = @centroids.map do |_, c|
        val = c.mean - x
        x = c.mean
        val
      end
      output += mean_arr
      # Variable length encoding of numbers
      c_arr = @centroids.each_with_object([]) do |(_, c), arr|
        k = 0
        n = c.n
        while n < 0 || n > 0x7f
          b = 0x80 | (0x7f & n)
          arr << b
          n = n >> 7
          k += 1
          fail 'Unreasonable large number' if k > 6
        end
        arr << n
      end
      output += c_arr
      output.pack("LdLf#{mean_arr.size}C#{c_arr.size}")
    end

    def as_json(_ = nil)
      @centroids.map { |_, c| c.as_json }
    end

    def bound_mean(x)
      upper = @centroids.upper_bound(x)
      lower = @centroids.lower_bound(x)
      [lower[1], upper[1]]
    end

    def bound_mean_cumn(cumn)
      last_c = nil
      bounds = []
      matches = @centroids.each do |k, v|
        if v.mean_cumn == cumn
          bounds << v
          break
        elsif v.mean_cumn > cumn
          bounds << last_c
          bounds << v
          break
        else
          last_c = v
        end
      end
      # If still no results, pick lagging value if any
      bounds << last_c if bounds.empty? && !last_c.nil?

      bounds
    end

    def compress!
      points = to_a
      reset!
      while points.length > 0
        push_centroid(points.delete_at(rand(points.length)))
      end
      _cumulate(true)
      nil
    end

    def compression
      1 / @delta
    end

    def find_nearest(x)
      return nil if size == 0

      ceil  = @centroids.upper_bound(x)
      floor = @centroids.lower_bound(x)

      return floor[1] if ceil.nil?
      return ceil[1]  if floor.nil?

      ceil_key  = ceil[0]
      floor_key = floor[0]

      if (floor_key - x).abs < (ceil_key - x).abs
        floor[1]
      else
        ceil[1]
      end
    end

    def p_rank(x)
      is_array = x.is_a? Array
      x = [x] unless is_array

      min = @centroids.first
      max = @centroids.last

      x.map! do |item|
        if size == 0
          nil
        elsif item < min[1].mean
          0.0
        elsif item > max[1].mean
          1.0
        else
          _cumulate(true)
          bound = bound_mean(item)
          lower, upper = bound
          mean_cumn = lower.mean_cumn
          if lower != upper
            mean_cumn += (item - lower.mean) * (upper.mean_cumn - lower.mean_cumn) / (upper.mean - lower.mean)
          end
          mean_cumn / @n
        end
      end
      is_array ? x : x.first
    end

    def percentile(p)
      is_array = p.is_a? Array
      p = [p] unless is_array
      p.map! do |item|
        unless (0..1).include? item
          fail ArgumentError, "p should be in [0,1], got #{item}"
        end
        if size == 0
          nil
        else
          _cumulate(true)
          h = @n * item
          lower, upper = bound_mean_cumn(h)
          if lower.nil? && upper.nil?
            nil
          elsif upper == lower || lower.nil? || upper.nil?
            (lower || upper).mean
          elsif h == lower.mean_cumn
            lower.mean
          else
            upper.mean
          end
        end
      end
      is_array ? p : p.first
    end

    def push(x, n = 1)
      x = [x] unless x.is_a? Array
      x.each { |value| _digest(value, n) }
    end

    def push_centroid(c)
      c = [c] unless c.is_a? Array
      c.each { |centroid| _digest(centroid.mean, centroid.n) }
    end

    def reset!
      @centroids.clear
      @n = 0
      @nreset += 1
      @last_cumulate = 0
    end

    def size
      @n || 0
    end

    def to_a
      @centroids.map { |_, c| c }
    end

    def self.from_bytes(bytes)
      format, compression, size = bytes.unpack('LdL')
      tdigest = new(1 / compression)

      start_idx = 16 # after header
      case format
      when VERBOSE_ENCODING
        array = bytes[start_idx..-1].unpack("d#{size}L#{size}")
        means, counts = array.each_slice(size).to_a if array.size > 0
      when SMALL_ENCODING
        means = bytes[start_idx..(start_idx + 4 * size)].unpack("f#{size}")
        # Decode delta encoding of means
        x = 0
        means.map! do |m|
          m += x
          x = m
          m
        end
        counts_bytes = bytes[(start_idx + 4 * size)..-1].unpack('C*')
        counts = []
        # Decode variable length integer bytes
        size.times do
          v = counts_bytes.shift
          z = 0x7f & v
          shift = 7
          while (v & 0x80) != 0
            fail 'Shift too large in decode' if shift > 28
            v = counts_bytes.shift || 0
            z += (v & 0x7f) << shift
            shift += 7
          end
          counts << z
        end
        # This shouldn't happen
        fail 'Mismatch' unless counts.size == means.size
      else
        fail 'Unknown compression format'
      end
      if means && counts
        means.zip(counts).each { |val| tdigest.push(val[0], val[1]) }
      end
      tdigest
    end

    def self.from_json(array)
      tdigest = new
      # Handle both string and symbol keys
      array.each { |a| tdigest.push(a['m'] || a[:m], a['n'] || a[:n]) }
      tdigest
    end

    private

    def _add_weight(nearest, x, n)
      unless x == nearest.mean
        nearest.mean += n * (x - nearest.mean) / (nearest.n + n)
      end

      _cumulate(false, true) if nearest.mean_cumn.nil?

      nearest.cumn += n
      nearest.mean_cumn += n / 2.0
      nearest.n += n
      @n += n

      nil
    end

    def _cumulate(exact = false, force = false)
      unless force
        factor = if @last_cumulate == 0
          Float::INFINITY
        else
          (@n.to_f / @last_cumulate)
        end
        return if @n == @last_cumulate || (!exact && @cx && @cx > (factor))
      end

      cumn = 0
      @centroids.each do |_, c|
        c.mean_cumn = cumn + c.n / 2.0
        cumn = c.cumn = cumn + c.n
      end
      @n = @last_cumulate = cumn
      nil
    end

    def _digest(x, n)
      # Use 'first' and 'last' instead of min/max because of performance reasons
      # This works because RBTree is sorted
      min = @centroids.first
      max = @centroids.last

      min = min.nil? ? nil : min[1]
      max = max.nil? ? nil : max[1]
      nearest = find_nearest(x)

      if nearest && nearest.mean == x
        _add_weight(nearest, x, n)
      elsif nearest == min
        _new_centroid(x, n, 0)
      elsif nearest == max
        _new_centroid(x, n, @n)
      else
        p = nearest.mean_cumn.to_f / @n
        max_n = (4 * @n * @delta * p * (1 - p)).floor
        if (max_n - nearest.n >= n)
          _add_weight(nearest, x, n)
        else
          _new_centroid(x, n, nearest.cumn)
        end
      end

      _cumulate(false)

      # If the number of centroids has grown to a very large size,
      # it may be due to values being inserted in sorted order.
      # We combat that by replaying the centroids in random order,
      # which is what compress! does
      if @centroids.size > (@k / @delta)
        compress!
      end

      nil
    end

    def _new_centroid(x, n, cumn)
      c = Centroid.new({ mean: x, n: n, cumn: cumn })
      @centroids[x] = c
      @n += n
      c
    end
  end
end
