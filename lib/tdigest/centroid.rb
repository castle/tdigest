module TDigest
  class Centroid
    attr_accessor :mean, :n, :cumn, :mean_cumn
    def initialize(mean, n, cumn, mean_cumn = nil)
      @mean      = mean
      @n         = n
      @cumn      = cumn
      @mean_cumn = mean_cumn
    end

    def as_json(_ = nil)
      { m: mean, n: n }
    end
  end
end
