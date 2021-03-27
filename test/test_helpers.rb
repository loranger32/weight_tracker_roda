ENV["RACK_ENV"] = "test"

require "bundler/setup"
Bundler.require :default, :test
require "minitest/autorun"
require "capybara/minitest"

Dotenv.load "../.env"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require_relative "../db/db"
require_relative "../app"

class HookedTestClass < Minitest::Test
  include Minitest::Hooks

  around(:all) do |&block|
    DB.transaction(rollback: :always){super(&block)}
  end

  around do |&block|
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true){super(&block)}
  end

  def before_all
    super
    load_fixtures
  end

  def after_all
    clean_fixtures
    super
  end

  def load_fixtures; end

  def clean_fixtures; end
end

class CapybaraTestCase < HookedTestClass
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include Rack::Test::Methods

  Capybara.app = WeightTracker::App.freeze.app

  def app
    Capybara.app
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
