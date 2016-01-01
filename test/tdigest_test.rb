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
      bytes = tdigest.as_bytes
      new_tdigest = ::TDigest::TDigest.from_bytes(bytes)
      new_tdigest.percentile(0.9).must_equal tdigest.percentile(0.9)
    end

    it 'handles zero size' do
      bytes = tdigest.as_bytes
      ::TDigest::TDigest.from_bytes(bytes).size.must_equal 0
    end

    it 'preserves compression' do
      td = ::TDigest::TDigest.new(0.001)
      bytes = td.as_bytes
      new_tdigest = ::TDigest::TDigest.from_bytes(bytes)
      new_tdigest.compression.must_equal td.compression
    end
  end

  describe 'JSON serialization' do
    it 'loads serialized data' do
      tdigest.push(60, 100)
      json = tdigest.as_json
      new_tdigest = ::TDigest::TDigest.from_json(json)
      new_tdigest.percentile(0.9).must_equal tdigest.percentile(0.9)
    end
  end

  describe '#percentile' do
    it 'returns nil if empty' do
      tdigest.percentile(0.90).must_be_nil # This should not crash
    end

    it 'raises ArgumentError of input not between 0 and 1' do
      -> { tdigest.percentile(1.1) }.must_raise ArgumentError
    end

    describe 'with only single value' do
      it 'returns the value' do
        tdigest.push(60, 100)
        tdigest.percentile(0.90).must_equal 60
      end

      it 'returns 0 for all percentiles when only 0 present' do
        tdigest.push(0)
        tdigest.percentile([0.0, 0.5, 1.0]).must_equal [0, 0, 0]
      end
    end

    describe 'with alot of uniformly distributed points' do
      it 'has minimal error' do
        N = 100_000
        maxerr = 0
        values = Array.new(N).map { rand }

        tdigest.push(values)
        tdigest.compress!

        0.step(1,0.1).each do |i|
          q = tdigest.percentile(i)
          maxerr = [maxerr, (i-q).abs].max
        end

        assert_operator maxerr, :<, 0.01
      end
    end
  end

  describe '#push' do
    it "calls _cumulate so won't crash because of uninitialized mean_cumn" do
      td = TDigest::TDigest.new
      td.push [125000000.0,
        104166666.66666666,
        135416666.66666666,
        104166666.66666666,
        104166666.66666666,
        93750000.0,
        125000000.0,
        62500000.0,
        114583333.33333333,
        156250000.0,
        124909090.90909092,
        104090909.0909091,
        135318181.81818184,
        104090909.0909091,
        104090909.0909091,
        93681818.18181819,
        124909090.90909092,
        62454545.45454546,
        114500000.00000001,
        156136363.63636366,
        123567567.56756756,
        102972972.97297296,
        133864864.86486486,
        102972972.97297296,
        102972972.97297296,
        92675675.67567568,
        123567567.56756756,
        61783783.78378378,
        113270270.27027026,
        154459459.45945945,
        123829787.23404256,
        103191489.36170213]
    end
  end
end
