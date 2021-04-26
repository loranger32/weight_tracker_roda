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

  def around_all
    DB.transaction(rollback: :always) do
      super
    end
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      super
    end
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

  def create_account!
    return if user_exist?
    visit "/create-account"
    fill_in "user_name", with: "Alice"
    fill_in "login", with: "alice@example.com"
    fill_in "login-confirm", with: "alice@example.com"
    fill_in "password", with: "foobar"
    fill_in "password-confirm", with: "foobar"
    click_on "Create Account"
  end

  def verify_account!
    verify_account_key = /<a href='http:\/\/www\.example\.com\/verify-account\?key=([\w|-]+)' method='post'>/i.match(mail_body(0))[1]

    visit "/verify-account?key=#{verify_account_key}"
    click_on "Verify Account"
    clean_mailbox
  end

  def setup_two_fa!(account_id)
    visit "/account"
    click_on "Setup 2FA"
    secret = page.find("#otp-secret-key").text

    totp = ROTP::TOTP.new(secret)
    
    fill_in "Password", with: "foobar"
    fill_in "Authentication Code", with: totp.now

    click_on "Setup TOTP Authentication"
  end

  def create_and_verify_account!
    create_account!
    verify_account!
  end  

  def logout!
    account = Account.all.first
    visit "/account"
    click_on "Log Out"
  end

  def login!
    raise StandardError, "No user to log in" unless user_exist?
    visit "/login"
    fill_in "login", with: "alice@example.com"
    fill_in "password", with: "foobar"
    click_on "Log In"
  end

  def user_exist?
    alice_account = Account.all.first
    alice_account && alice_account.user_name == "Alice" && alice_account.email == "alice@example.com"
  end

  def mails_count
    Mail::TestMailer.deliveries.length
  end

  def clean_mailbox
    Mail::TestMailer.deliveries.clear
  end

  def mail_body(mail_index)
    Mail::TestMailer.deliveries[mail_index].body.raw_source
  end

  def mail_to(mail_index)
    Mail::TestMailer.deliveries[mail_index].to[0]
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
    clean_mailbox
  end
end

