require_relative "../app"
require "test/unit"
require "rack/test"

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App
  end

  def test_index
    get '/'
    assert last_response.ok?
    assert_equal 200, last_response.status
  end
end
