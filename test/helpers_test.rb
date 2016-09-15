require_relative "../helpers"
require "test/unit"
require "rack/test"

class HelpersTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Helpers

  def test_compute_time
    result = compute_time Hash["start", "2016-09-13 17:01:18 +0800", "stop", "2016-09-15 17:04:38 +0800"]
    assert !result.include?("day")
    assert_equal result, "48 hours, 3 minutes and 20 seconds"
  end
end
