require 'rubygems'
require 'sinatra'
require 'dotenv'

get "/" do
  "release timer"
end

post "/" do
  puts self.inspect
end

post "/start" do
  puts "M"*200
  puts params.inspect
  puts "M"*200
end
