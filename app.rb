require 'rubygems'
require 'sinatra'
require 'redis'
require 'dotenv'
require './helpers'

class App < Sinatra::Base

  configure :production do
    $redis = Redis.new(url: ENV["REDISTOGO_URL"], driver: :hiredis)
  end

  configure :development do
    Dotenv.load

    $redis = Redis.new
  end

  configure do
    set :slack_incoming_url, ENV['SLACK_INCOMING_URL']
    set :slack_start_timer_token, ENV['SLACK_START_TIMER_TOKEN']
    set :slack_stop_timer_token, ENV['SLACK_STOP_TIMER_TOKEN']
    set :slack_enable_deploy_watch, ENV['SLACK_ENABLE_DEPLOY_WATCH']
    set :slack_deploy_qlearn_token, ENV['SLACK_DEPLOY_QLEARN_TOKEN']
    set :slack_deploy_api_token, ENV['SLACK_DEPLOY_API_TOKEN']
    set :slack_deploy_qlink_token, ENV['SLACK_DEPLOY_QLINK_TOKEN']
    set :slack_deploy_video_payment_token, ENV['SLACK_DEPLOY_VIDEO_PAYMENT_TOKEN']
    set :slack_deploy_qlink_react_token, ENV['SLACK_DEPLOY_QLINK_REACT_TOKEN']
    set :slack_deploy_microservices_token, ENV['SLACK_DEPLOY_MICROSERVICES_TOKEN']
    set :slack_channel, ENV['SLACK_CHANNEL']
    set :slack_username, ENV['SLACK_USERNAME']
    set :slack_avatar, ENV['SLACK_AVATAR']
  end

  helpers do
    include Helpers
  end

  get "/" do
    begin
      times = $redis.smembers('times').sort.reverse.flat_map { |time| parse_time! $redis.hgetall(time) }
      times.map!{ | t | t.merge({"total" => compute_time_in_english(t)}) }
      times.sort_by { |t| t['total'] ? t['total'][/^[0-9]+/].to_i : 0 }.last&.merge!({"win" => true})
      haml :index, :locals => { times: times }
    rescue
      nil
    end
  end

  get "/check" do
    "#{compute_time_in_english last_record}" if has_the_time? last_record
  end

  post "/start" do
    if settings.slack_start_timer_token == params['token']
      new_entry = new_record_id
      $redis.hmset(new_entry, "start", Time.now)
      $redis.set('test_status', RELEASE_STANDBY) # add flag for tracking release testing status. otherwise deploy notification will be too noisy every time app is redeployed

      RELEASE_APPS.each do |app|
        $redis.hmset(new_entry, app, false)
      end

      $redis.sadd 'times', new_entry

      200
    end
  end

  post "/deploy/:app" do
    return 503 if settings.slack_enable_deploy_watch.nil? or $redis.get('test_status') == RELEASE_STARTED

    deploy_tokens = [
      # Ref: https://github.com/quipper/quipper/issues/15518
      # settings.slack_deploy_qlearn_token,
      # settings.slack_deploy_api_token,
      # settings.slack_deploy_qlink_token,
      # settings.slack_deploy_video_payment_token,
      # settings.slack_deploy_qlink_react_token,
      settings.slack_deploy_microservices_token
    ]

    if !params['token'].nil? and deploy_tokens.include? params['token'] and !$redis.hgetall(last_record_id).key?("stop") # check tokens and if there's an active release
      $redis.hmset(last_record_id, params[:app], true)
      send_deploy_status_to_slack $redis.hgetall(last_record_id)
        .select { |key| RELEASE_APPS.include? key }
    else
      417
    end
  end

  post "/stop" do
    if settings.slack_stop_timer_token == params['token']
      $redis.hmset last_record_id, "stop", Time.now
      send_time_to_slack
      send_jp_holiday_notification_to_slack

      200
    end
  end
end
