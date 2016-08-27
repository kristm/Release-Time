require 'rubygems'
require 'sinatra'
require 'httparty'
require 'pstore'
require 'dotenv'

class App < Sinatra::Base

  configure do
    Dotenv.load if ENV['RACK_ENV'] == 'development'
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
      timer = DB[:times].last
      t = timer[:stop] - timer[:start]
      mm, ss = t.divmod(60)
      hh, mm = mm.divmod(60)
      dd, hh = hh.divmod(24)
      "%d days, %d hours, %d minutes and %d seconds" % [dd, hh, mm, ss]
    end

    def has_the_time?
      !DB[:times].empty? and DB[:times].last[:stop] > DB[:times].last[:start]
    end
  end

  get "/" do
    "#{DB.inspect}"
  end

  get "/slack" do
    send_time_to_slack if has_the_time?
  end

  post "/start" do
    if settings.slack_start_timer_token == params['token']
      DB[:times] << { start: Time.now }

      200
    end
  end

  post "/stop" do
    if settings.slack_stop_timer_token == params['token']
      DB[:times].last.merge! stop: Time.now
      send_time_to_slack

      200
    end
  end
end
