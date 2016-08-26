require 'rubygems'
require 'sinatra'
require 'httparty'
require 'dotenv'

class App < Sinatra::Base
  set :cache, {}

  configure do
    Dotenv.load if ENV['RACK_ENV'] == 'development'
    set :slack_incoming_url, ENV['SLACK_INCOMING_URL']
    set :slack_start_timer_token, ENV['SLACK_START_TIMER_TOKEN']
    set :slack_stop_timer_token, ENV['SLACK_STOP_TIMER_TOKEN']
  end

  helpers do
    def send_time_to_slack
      HTTParty.post(settings.slack_incoming_url,
                    body: {
                      channel: "#release-test",
                      username: "Release time",
                      text: "_#{computed_time}_",
                      icon_emoji: ":pangasar:"
                    }.to_json,
                    headers: {'content-type' => 'application/json'}
                   )
    end

    def computed_time
      if App.cache['stop'] and App.cache['stop'] > App.cache['start']
        t = App.cache['stop'] - App.cache['start']
        mm, ss = t.divmod(60)
        hh, mm = mm.divmod(60)
        dd, hh = hh.divmod(24)
        "%d days, %d hours, %d minutes and %d seconds" % [dd, hh, mm, ss]
      end
    end

    def has_the_time?
      App.cache.key? 'start' and App.cache.key? 'stop' and App.cache['stop'] > App.cache['start']
    end
  end

  get "/" do
    "#{App.cache.inspect}"
  end

  get "/slack" do
    send_time_to_slack if has_the_time?
  end

  post "/start" do
    App.cache['start'] = Time.now unless settings.slack_start_timer_token == params['token']
  end

  post "/stop" do
    unless settings.slack_stop_timer_token == params['token']
      App.cache['stop'] = Time.now
      send_time_to_slack
    end
  end
end
