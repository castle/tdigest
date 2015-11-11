require 'test_helper'
require 'benchmark'

class TDigestTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::TDigest::VERSION
  end
end
