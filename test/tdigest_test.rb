require 'test_helper'

class TDigestTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::TDigest::VERSION
  end

  describe '#percentile' do
    it 'returns nil if empty' do
      tdigest = ::TDigest::TDigest.new
      tdigest.percentile(0.90).must_be_nil # This should not crash
    end

    describe 'with only signle value' do
      it 'returns the value' do
        tdigest = ::TDigest::TDigest.new
        tdigest.push(60, 100)
        tdigest.percentile(0.90).must_equal 60
      end
    end
  end
end
