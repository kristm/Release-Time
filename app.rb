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
    set :slack_channel, ENV['SLACK_CHANNEL']
    set :slack_username, ENV['SLACK_USERNAME']
    set :slack_avatar, ENV['SLACK_AVATAR']
  end

  helpers do
    include Helpers
  end

  get "/" do
    times = $redis.smembers('times').sort.reverse.flat_map { |time| parse_time! $redis.hgetall(time) }
    haml :index, :locals => { times: times.map { | t | t.merge({"total" => compute_time_in_english(t)}) } }
  end

  get "/check" do
    "#{compute_time_in_english last_record}" if has_the_time? last_record
  end

  post "/start" do
    if settings.slack_start_timer_token == params['token']
      $redis.hmset(new_record_id, "start", Time.now)
      $redis.sadd 'times', new_record_id

      200
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
