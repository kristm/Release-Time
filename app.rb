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
    set :slack_channel, ENV['SLACK_CHANNEL']
    set :slack_username, ENV['SLACK_USERNAME']
    set :slack_avatar, ENV['SLACK_AVATAR']
  end

  helpers do
    include Helpers
  end

  get "/" do
    times = $redis.smembers('times').sort.reverse.flat_map { |time| parse_time! $redis.hgetall(time) }
    times.map!{ | t | t.merge({"total" => compute_time_in_english(t)}) }
    times.sort_by { | t | t['total'] || '' }.last&.merge!({"win" => true})
    haml :index, :locals => { times: times }
  end

  get "/check" do
    "#{compute_time_in_english last_record}" if has_the_time? last_record
  end

  post "/start" do
    if settings.slack_start_timer_token == params['token']
      $redis.hmset(new_record_id, "start", Time.now)

      RELEASE_APPS.each do |app|
        $redis.hmset(new_record_id, app, false)
      end

      $redis.hmset(new_record_id, "start", Time.now)
      $redis.sadd 'times', new_record_id

      200
    end
  end

  post "/deploy/:app" do
    return 503 if settings.slack_enable_deploy_watch.nil?

    if [:qlearn,
        :api,
        :qlink,
        :video_payment,
        :qlink_react].map { |app| settings.send("slack_deploy_#{app}_token".to_sym) }.include? params['token'] and !$redis.hgetall(last_record_id).key?("stop") # check tokens and if there's an active release
      $redis.hmset(last_record_id, params[:app], true)
      send_deploy_status_to_slack $redis.hgetall(last_record_id)
        .select { |key| RELEASE_APPS.include? key }
    end
  end

  post "/stop" do
    if settings.slack_stop_timer_token == params['token']
      $redis.hmset last_record_id, "stop", Time.now
      send_time_to_slack

      200
    end
  end
end
