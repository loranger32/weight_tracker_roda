require "bundler/setup"

if ENV["RACK_ENV"] == "production"
  Bundler.require(:default, :production)
else
  require "dotenv"
  Dotenv.load
  if ENV["RACK_ENV"] == "development"
    Bundler.require(:default, :development)
  elsif ENV["RACK_ENV"] == "test"
    Bunlder.require(:default, :test)
  else
    Bunlder.require(:default)
  end
end

require_relative "app"

run WeightTracker::App.freeze.app
