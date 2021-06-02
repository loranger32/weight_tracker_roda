ENV["RACK_ENV"] = "test"

require "bundler/setup"
Bundler.require :default, :test
require "minitest/autorun"
require "capybara/minitest"

Dotenv.load "../.env"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require_relative "../db/db"
require_relative "../app"

class TestAccountMismatchError < StandardError; end

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

  def create_account!(user_name: "Alice", email: "alice@example.com", password: "foobar")
    return existing_account if existing_account = Account.where(email: email).first

    visit "/create-account"
    fill_in "user_name", with: user_name
    fill_in "login", with: email
    fill_in "login-confirm", with: email
    fill_in "password", with: password
    fill_in "password-confirm", with: password
    click_on "Create Account"
    Account.where(email: email).first
  end

  def verify_account!(account = nil)
    account ||= Account.where(email: "alice@example.com").first
    raise TestAccountMismatchError unless account && account.email == last_mail_to_field
    verify_account_key = /<a href='http:\/\/www\.example\.com\/verify-account\?key=([\w|-]+)' method='post'>/i.match(last_mail_body)[1]
    visit "/verify-account?key=#{verify_account_key}"
    click_on "Verify Account"
    clean_mailbox
    account.reload
  end

  def create_and_verify_account!(user_name: "Alice", email: "alice@example.com" , password: "foobar")
    account = create_account!(user_name: user_name, email: email, password: password)
    verify_account!(account)
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

  def logout!(account = nil)
    account ||= Account.where(email: "alice@example.com").first
    visit "/account"
    click_on "Log Out"
  end

  def login!(email: "alice@example.com", password: "foobar")
    raise StandardError, "No user to log in" unless user_exist?(email: email)
    visit "/login"
    fill_in "login", with: email
    fill_in "password", with: password
    click_on "Log In"
    Account.where(email: "alice@example.com").first
  end

  def user_exist?(email: "alice@example.com")
    Account.where(email: email).first
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

  def last_mail_body
    Mail::TestMailer.deliveries.last.body.raw_source
  end

  def mail_to(mail_index)
    Mail::TestMailer.deliveries[mail_index].to[0]
  end

  def last_mail_to_field
    mail_to(-1)
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
    clean_mailbox
  end
end

