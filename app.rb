require 'rubygems'
require 'sinatra'
require 'httparty'
require 'dotenv'

class App < Sinatra::Base
  set :cache, {}

  configure do
    set :slack_incoming_url, "https://hooks.slack.com/services/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"
  end

  get "/" do
    puts "="*100
    puts "#{App.cache.inspect}"
    "#{App.cache.inspect}"
  end

  post "/start" do
    puts "M"*200
    puts params.inspect
    puts "M"*200
    App.cache['start'] = Time.now
  end

  post "/stop" do
    App.cache['stop'] = Time.now
    #curl -X POST --data-urlencode 'payload={"channel": "#release-test", "username": "webhookbot", "text": "This is posted to #release-test and cos from a bot named webhookbot.", "icon_emoji": ":krist:"}' https://hooks.slack.com/services/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
    HTTParty.post(settings.slack_incoming_url,
                  body: { 
                    payload: {
                      channel: "#release-test",
                      username: "webhookbot",
                      text: "Release time: #{App.cache['stop'] - App.cache['start']}",
                      icon_emoji: ":krist:",
                    }
                  }
                 )
  end
end
