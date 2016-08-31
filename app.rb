require 'rubygems'
require 'sinatra'
require 'httparty'
require 'redis'
require 'dotenv'

class App < Sinatra::Base

  configure :production do
    $redis = Redis.new(url: ENV["REDISTOGO_URL"], driver: :hiredis)
  end

  configure :development do
    Dotenv.load if ENV['RACK_ENV'] == 'development'

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
    def send_time_to_slack
      HTTParty.post(settings.slack_incoming_url,
                    body: {
                      channel: settings.slack_channel,
                      username: settings.slack_username,
                      text: "_#{computed_time}_",
                      icon_emoji: settings.slack_avatar
                    }.to_json,
                    headers: {'content-type' => 'application/json'}
                   )
    end

    def computed_time
      timer = last_record
      t = Time.parse(timer["stop"]) - Time.parse(timer["start"]) #why redis no store time?
      mm, ss = t.divmod(60)
      hh, mm = mm.divmod(60)
      dd, hh = hh.divmod(24)
      "%d days, %d hours, %d minutes and %d seconds" % [dd, hh, mm, ss]
    end

    def has_the_time?
      last_record["stop"] >= last_record["start"]
    rescue
      false
    end

    def new_record_id
      "release:#{Time.now.to_i}"
    end

    def last_record_id
      $redis.smembers('times').last
    end

    def last_record
      $redis.hgetall last_record_id
    end
  end

  get "/" do
    "#{$redis.smembers('times').map { |time| $redis.hgetall time }.flatten}"
  end

  get "/check" do
    "#{computed_time}" if has_the_time?
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
