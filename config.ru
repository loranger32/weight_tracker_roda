require "bundler/setup"

if ENV["RACK_ENV"] == "production"
  Bundler.require(:default, :production)
else
  require "dotenv"
  Dotenv.load 
  if ENV["RACK_ENV"] == 'development'
    Bundler.require(:default, :development)  
  elsif ENV['RACK_ENV'] == "test"
    Bunlder.require(:default, :test)
  else
    Bunlder.require(:default)
  end
end

require_relative 'app'
require_relative 'helpers/app_helpers'
require_relative 'helpers/view_helpers'

run WeightTracker::App.freeze.app
