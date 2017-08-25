require_relative "../app"
require "test/unit"
require "rack/test"
require "mocha/test_unit"
require "fakeredis"

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

  def test_deploy_returns_503_if_flag_not_set
    post '/deploy/app'
    assert_equal 503, last_response.status
  end

  def test_deploy_returns_503_if_enable_flag_not_set
    app.settings.expects(:slack_enable_deploy_watch).returns(nil)
    post '/deploy/app'
    assert_equal 503, last_response.status
  end

  def test_deploy_returns_503_if_test_started
    app.settings.expects(:slack_enable_deploy_watch).returns('ok')
    $redis = Redis.new
    $redis.set('test_status', 'started')
    post '/deploy/app'
    assert_equal 503, last_response.status
  end

  def test_deploy_returns_417_if_no_record_found
    app.settings.expects(:slack_enable_deploy_watch).returns('ok')
    $redis = Redis.new
    $redis.set('test_status', 'standby')
    post '/deploy/app'
    assert_equal 417, last_response.status
  end
end
