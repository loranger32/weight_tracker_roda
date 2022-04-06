ENV["RACK_ENV"] = "test"

require "bundler/setup"
Bundler.require :default, :test
require "minitest/autorun"
require "capybara/minitest"
require "sucker_punch/testing/inline"

Dotenv.load "../.env"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require_relative "../db/db"
require_relative "../app"

class TestAccountMismatchError < StandardError; end

class HookedTestClass < Minitest::Test
  include Minitest::Hooks

  def clean_test_db!
    tables = [:admins, :batches, :mensurations, :entries, :account_active_session_keys,
      :account_authentication_audit_logs, :account_email_auth_keys, :account_lockouts,
      :account_login_change_keys, :account_login_failures, :account_otp_keys,
      :account_password_reset_keys, :account_recovery_codes, :account_session_keys,
      :account_verification_keys, :accounts]
    tables.each { |table| DB[table].delete }
    tables.each { |table| DB.reset_primary_key_sequence(table) }
  end
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
    if (existing_account = Account.where(email: email).first)
      login!(email: email, password: password)
      return existing_account 
    end

    visit "/create-account"
    fill_in "user_name", with: user_name
    fill_in "login", with: email
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

  def create_and_verify_account!(user_name: "Alice", email: "alice@example.com", password: "foobar")
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

  def logout!
    visit "/account"
    click_on "Log Out"
    assert_current_path "/logout"
    click_on "Logout"
  end

  def login!(email: "alice@example.com", password: "foobar")
    raise StandardError, "No user to log in" unless user_exist?(email: email)
    visit "/login"
    within("form#login-form") do
      fill_in "login", with: email
      fill_in "password", with: password
      click_on "Login"
    end
    Account.where(email: email).first
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
