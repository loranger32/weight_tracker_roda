require 'sequel'
require 'logger'

module MyApp
  if ENV['RACK_ENV'] == 'test'
    DB = Sequel.connect(ENV.fetch('TEST_DATABASE_URL'))
  else
    DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
  end

  DB.loggers << Logger.new($stdout) unless ENV['RACK_ENV'] == 'test'

  require_relative "../models/entry"
  require_relative "../models/account"
end
