module TDigest
  class Centroid
    attr_accessor :mean, :n, :cumn, :mean_cumn
    def initialize(params = {})
      params.each do |p, value|
        send("#{p}=", value)
      end
    end

    def as_json(_ = nil)
      { m: mean, n: n }
    end
  end
end
