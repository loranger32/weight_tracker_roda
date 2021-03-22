require "sequel"
require "logger"

module MyApp
  DB = if ENV["RACK_ENV"] == "test"
    Sequel.connect(ENV.fetch("TEST_DATABASE_URL"))
  else
    Sequel.connect(ENV.fetch("DATABASE_URL"))
  end

  DB.loggers << Logger.new($stdout) unless ENV["RACK_ENV"] == "test"

  require_relative "../models/entry"
  require_relative "../models/account"
end
