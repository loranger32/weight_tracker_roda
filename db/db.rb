require "sequel"
require "logger"

Sequel::Model.plugin :force_encoding, "UTF-8"
Sequel::Model.plugin :column_encryption do |enc|
  enc.key 0, ENV["SEQUEL_COLUMN_ENCRYPTION_KEY"]
end

module WeightTracker
  DB = if ENV["RACK_ENV"] == "test"
    Sequel.connect(ENV.fetch("TEST_DATABASE_URL"))
  else
    Sequel.connect(ENV.fetch("DATABASE_URL"))
  end

  DB.loggers << Logger.new($stdout) unless ENV["RACK_ENV"] == "test"
end

require_relative "../models/account"
require_relative "../models/entry"
require_relative "../models/admin"
require_relative "../models/batch"
require_relative "../models/mensuration"

# In the irb console, save some typing when accessing the DB object
DB = WeightTracker::DB
