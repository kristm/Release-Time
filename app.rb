require 'rubygems'
require 'sinatra'
require 'httparty'
require 'dotenv'

class App < Sinatra::Base
  set :cache, {}

  configure do
    set :slack_incoming_url, "https://hooks.slack.com/services/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"
  end

  helpers do
    def send_time_to_slack
      HTTParty.post(settings.slack_incoming_url,
                    body: {
                      channel: "#release-test",
                      username: "Release time",
                      text: "_#{computed_time}_",
                      icon_emoji: ":krist:"
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
      !App.cache.empty? and App.cache.key? 'start' and App.cache.key? 'stop'
    end
  end

  get "/" do
    puts "="*100
    puts "#{App.cache.inspect}"
    "#{App.cache.inspect}"
  end

  get "/slack" do
    send_time_to_slack if has_the_time?
  end

  post "/start" do
    puts "M"*200
    puts params.inspect
    puts "M"*200
    App.cache['start'] = Time.now
  end

  post "/stop" do
    App.cache['stop'] = Time.now
  end
end
