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

    describe 'with only signle value' do
      it 'returns the value' do
        tdigest.push(60, 100)
        tdigest.percentile(0.90).must_equal 60
      end
    end
  end
end
