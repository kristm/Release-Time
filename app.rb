require 'rubygems'
require 'sinatra'
require 'dotenv'

get "/" do
  "release timer"
end

post "/" do
  puts self.inspect
end
