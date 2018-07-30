require_relative "../helpers"
require "test/unit"
require "rack/test"

class HelpersTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Helpers

  def test_compute_time
    result = compute_time Hash["start", "2016-09-13 17:01:18 +0800", "stop", "2016-09-15 17:04:38 +0800"]
    assert !result.include?("day")
    assert_equal result, [48, 3, 20]
  end

  def test_deploy_status_in_english
    result = deploy_status_in_english({"Microservices": true, "QLink-react": false});
    assert_equal result, "> Deploy status\nMicroservices :x: | QLink-react :x:"
  end
end
