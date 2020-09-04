# frozen_string_literal: true

require 'test_helper'

class TDigestTest < Minitest::Test
  extend Minitest::Spec::DSL

  let(:tdigest) { ::TDigest::TDigest.new }

  def test_that_it_has_a_version_number
    refute_nil ::TDigest::VERSION
  end

  describe 'byte serialization' do
    it 'loads serialized data' do
      tdigest.push(60, 100)
      10.times { tdigest.push(rand * 100) }
      bytes = tdigest.as_bytes
      new_tdigest = ::TDigest::TDigest.from_bytes(bytes)
      _(new_tdigest.percentile(0.9)).must_equal tdigest.percentile(0.9)
      _(new_tdigest.as_bytes).must_equal bytes
    end

    it 'handles zero size' do
      bytes = tdigest.as_bytes
      _(::TDigest::TDigest.from_bytes(bytes).size).must_equal 0
    end

    it 'preserves compression' do
      td = ::TDigest::TDigest.new(0.001)
      bytes = td.as_bytes
      new_tdigest = ::TDigest::TDigest.from_bytes(bytes)
      _(new_tdigest.compression).must_equal td.compression
    end
  end

  describe 'small byte serialization' do
    it 'loads serialized data' do
      tdigest.push(60, 1000)
      10.times { tdigest.push(rand * 10) }
      bytes = tdigest.as_small_bytes
      new_tdigest = ::TDigest::TDigest.from_bytes(bytes)
      # Expect some rounding error due to compression
      _(new_tdigest.percentile(0.9).round(5)).must_equal(
        tdigest.percentile(0.9).round(5)
      )
      _(new_tdigest.as_small_bytes).must_equal bytes
    end

    it 'handles zero size' do
      bytes = tdigest.as_small_bytes
      _(::TDigest::TDigest.from_bytes(bytes).size).must_equal 0
    end
  end

  describe 'JSON serialization' do
    it 'loads serialized data' do
      tdigest.push(60, 100)
      json = tdigest.as_json
      new_tdigest = ::TDigest::TDigest.from_json(json)
      _(new_tdigest.percentile(0.9)).must_equal tdigest.percentile(0.9)
    end
  end

  describe '#percentile' do
    it 'returns nil if empty' do
      _(tdigest.percentile(0.90)).must_be_nil # This should not crash
    end

    it 'raises ArgumentError of input not between 0 and 1' do
      _(-> { tdigest.percentile(1.1) }).must_raise ArgumentError
    end

    describe 'with only single value' do
      it 'returns the value' do
        tdigest.push(60, 100)
        _(tdigest.percentile(0.90)).must_equal 60
      end

      it 'returns 0 for all percentiles when only 0 present' do
        tdigest.push(0)
        _(tdigest.percentile([0.0, 0.5, 1.0])).must_equal [0, 0, 0]
      end
    end

    describe 'with alot of uniformly distributed points' do
      it 'has minimal error' do
        seed = srand(1234) # Makes the values a proper fixture
        N = 100_000
        maxerr = 0
        values = Array.new(N).map { rand }
        srand(seed)

        tdigest.push(values)
        tdigest.compress!

        0.step(1, 0.1).each do |i|
          q = tdigest.percentile(i)
          maxerr = [maxerr, (i - q).abs].max
        end

        assert_operator maxerr, :<, 0.01
      end
    end
  end

  describe '#push' do
    it "calls _cumulate so won't crash because of uninitialized mean_cumn" do
      td = TDigest::TDigest.new
      td.push [125_000_000.0,
               104_166_666.66666666,
               135_416_666.66666666,
               104_166_666.66666666,
               104_166_666.66666666,
               93_750_000.0,
               125_000_000.0,
               62_500_000.0,
               114_583_333.33333333,
               156_250_000.0,
               124_909_090.90909092,
               104_090_909.0909091,
               135_318_181.81818184,
               104_090_909.0909091,
               104_090_909.0909091,
               93_681_818.18181819,
               124_909_090.90909092,
               62_454_545.45454546,
               114_500_000.00000001,
               156_136_363.63636366,
               123_567_567.56756756,
               102_972_972.97297296,
               133_864_864.86486486,
               102_972_972.97297296,
               102_972_972.97297296,
               92_675_675.67567568,
               123_567_567.56756756,
               61_783_783.78378378,
               113_270_270.27027026,
               154_459_459.45945945,
               123_829_787.23404256,
               103_191_489.36170213]
    end

    it 'does not blow up if data comes in sorted' do
      tdigest.push(0..10_000)
      _(tdigest.centroids.size).must_be :<, 5_000
      tdigest.compress!
      _(tdigest.centroids.size).must_be :<, 1_000
    end
  end

  describe '#size' do
    it 'reports the number of observations' do
      n = 10_000
      n.times { tdigest.push(rand) }
      tdigest.compress!
      _(tdigest.size).must_equal n
    end
  end

  describe '#+' do
    it 'works with empty tdigests' do
      other = ::TDigest::TDigest.new(0.001, 50, 1.2)
      _((tdigest + other).centroids.size).must_equal 0
    end

    describe 'adding two tdigests' do
      before do
        @other = ::TDigest::TDigest.new(0.001, 50, 1.2)
        [tdigest, @other].each do |td|
          td.push(60, 100)
          10.times { td.push(rand * 100) }
        end
      end

      it 'has the parameters of the left argument (the calling tdigest)' do
        new_tdigest = tdigest + @other
        _(new_tdigest.instance_variable_get(:@delta)).must_equal tdigest.instance_variable_get(:@delta)
        _(new_tdigest.instance_variable_get(:@k)).must_equal tdigest.instance_variable_get(:@k)
        _(new_tdigest.instance_variable_get(:@cx)).must_equal tdigest.instance_variable_get(:@cx)
      end

      it 'results in a tdigest with number of centroids less than or equal to the combined centroids size' do
        new_tdigest = tdigest + @other
        _(new_tdigest.centroids.size).must_be :<=, tdigest.centroids.size + @other.centroids.size
      end

      it 'has the size of the two digests combined' do
        new_tdigest = tdigest + @other
        _(new_tdigest.size).must_equal (tdigest.size + @other.size)
      end
    end
  end

  describe '#merge!' do
    it 'works with empty tdigests' do
      other = ::TDigest::TDigest.new(0.001, 50, 1.2)
      tdigest.merge!(other)
      _(tdigest.centroids.size).must_equal 0
    end

    describe 'with populated tdigests' do
      before do
        @other = ::TDigest::TDigest.new(0.001, 50, 1.2)
        [tdigest, @other].each do |td|
          td.push(60, 100)
          10.times { td.push(rand * 100) }
        end
      end

      it 'has the parameters of the calling tdigest' do
        vars = %i[@delta @k @cs]
        expected = Hash[vars.map { |v| [v, tdigest.instance_variable_get(v)] }]
        tdigest.merge!(@other)
        vars.each do |v|
          if expected[v].nil?
            _(tdigest.instance_variable_get(v)).must_be_nil
          else
            _(tdigest.instance_variable_get(v)).must_equal expected[v]
          end
        end
      end

      it 'results in a tdigest with number of centroids less than or equal to the combined centroids size' do
        combined_size = tdigest.centroids.size + @other.centroids.size
        tdigest.merge!(@other)
        _(tdigest.centroids.size).must_be :<=, combined_size
      end

      it 'has the size of the two digests combined' do
        combined_size = tdigest.size + @other.size
        tdigest.merge!(@other)
        _(tdigest.size).must_equal combined_size
      end
    end
  end
end
