ENV["RACK_ENV"] = "test"

require "bundler/setup"
Bundler.require :default, :test
Dotenv.load
