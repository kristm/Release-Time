require './app'

#Sass::Plugin.options[:style] = :compressed
#use Sass::Plugin::Rack
$stdout.sync = true

run Sinatra::Application
