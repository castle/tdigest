require 'test_helper'

class TDigestTest < Minitest::Test
  extend Minitest::Spec::DSL

  let(:tdigest) { ::TDigest::TDigest.new }

  def test_that_it_has_a_version_number
    refute_nil ::TDigest::VERSION
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
        N = 10_000
        maxerr = 0
        values = Array.new(N).map { rand }

        tdigest.push(values)
        tdigest.compress!

        0.step(1,0.1).each do |i|
          q = tdigest.percentile(i)
          maxerr = [maxerr, (i-q).abs].max
        end

        assert_operator maxerr, :<, 0.02
      end
    end
  end
end
