source "https://rubygems.org"
ruby File.read(File.join(File.dirname(__FILE__), ".ruby-version")).strip

gem "sinatra"
gem "haml", "~> 5.0.4"
gem "httparty"
gem "redis"
gem "hiredis"
gem "dotenv"

group :development, :test do
  gem "pry"
  gem "fakeredis"
  gem "mocha"
end
