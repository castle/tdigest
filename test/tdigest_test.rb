require 'test_helper'
require 'benchmark'

class TDigestTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::TDigest::VERSION
  end

  def test_percentile_edge_case
    tdigest = ::TDigest::TDigest.new
    tdigest.push(60, 100)
    pct = tdigest.percentile(0.90) # This should not crash
    assert_equal nil, pct
  end
end
