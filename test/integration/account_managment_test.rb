require_relative "../test_helpers"

module GenericAccountManagmentActionsTests
  def test_user_can_visit_account_page
    visit "/account"
    assert_current_path "/account"
    assert_content @alice_account.user_name, count: 2
    assert_content @alice_account.email, count: 1
    assert_link "Change User Name"
    assert_link "Change Email"
    assert_link "Change Password"
    assert_link "Security Log"
    assert_link "Export Data"
    assert_link "Log Out"
    assert_link "Close Account"
  end

  def test_user_can_change_user_name
    new_user_name = "Alice In Wonderland"
    visit "/change-user-name"
    fill_in "user_name", with: new_user_name
    fill_in "password", with: "foobar"
    click_on "Change User Name"

    assert_equal new_user_name, Account[@alice_account.id].user_name
    assert_current_path "/account"
    assert_css ".alert-success"
    assert_content new_user_name
  end

  def test_security_log
    logout!

    login!
    logout!

    visit "/login"
    within("form#login-form") do
      fill_in "login", with: "alice@example.com"
      fill_in "password", with: "wrongpassword"
      click_on "Login"
    end
    login!

    visit "/security-log"

    assert_current_path "/security-log"
    assert_content "Review the access to your account"
    within("table") do
      assert_content "create_account", count: 1
      assert_content /\slogin\s/, count: 3
      assert_content "logout", count: 2
      assert_content "login_failure", count: 1
    end
  end

  def test_security_logs_are_capped_to_100_rows
    current_number_of_rows = DB[:account_authentication_audit_logs].where(account_id: 1).count
    DB.transaction do
      110.times { DB[:account_authentication_audit_logs].insert(account_id: 1, message: "test login #{_1}}") }
    end
    assert_equal current_number_of_rows + 110, DB[:account_authentication_audit_logs].where(account_id: 1).count

    login!
    # Don't know why it's 101 instead of 100
    assert_equal 101, DB[:account_authentication_audit_logs].where(account_id: 1).count
  end

  def test_export_data_page
    visit "/export-data"

    assert_current_path "/export-data"
    assert_content "Export Your Data"
    assert_content "JSON"

    assert_selector "input", count: 1
  end

  def test_export_data_to_json
    pre_existing_data_files = Dir.glob("tmp/wt_data_Alice_*.json")

    visit "/export-data"

    click_on "Download"

    existing_data_files = Dir.glob("tmp/wt_data_Alice_*.json")

    assert_equal pre_existing_data_files.size + 1, existing_data_files.size

    FileUtils.remove_entry_secure((existing_data_files - pre_existing_data_files)[0])
  end

  def test_close_account_page
    visit "/close-account"
    assert_current_path "/close-account"

    click_on "Take me to the export data page"
    assert_current_path "/export-data"

    visit "/close-account"
    click_on "I don't want to close my account"
    assert_current_path "/account"

    visit "/close-account"
    refute_checked_field "I have backed up my data"
    assert_css ".disabled"
  end

  def test_cannot_close_account_if_checkbox_is_not_checked
    assert_equal @test_account_status, @alice_account.status_id

    visit "/close-account"

    fill_in "password", with: "foobar"
    click_on "Close Account"

    assert_current_path "/close-account"
    assert_css ".alert-danger"
    assert_content "You did not confirm you made a backup of your data"

    assert_equal @test_account_status, @alice_account.status_id
  end

  def test_can_close_account_if_checkbox_is_checked
    assert_equal @test_account_status, @alice_account.status_id

    visit "/close-account"

    check "I have backed up my data"
    fill_in "password", with: "foobar"
    click_on "Close Account"

    assert_current_path "/login"

    assert_equal 3, Account[@alice_account.id].status_id

    within("form#login-form") do
      fill_in "Email", with: "Alice"
      fill_in "Password", with: "foobar"
      click_on "Login"
    end

    assert_current_path "/login"
    assert_css ".alert-danger"
  end

  def test_account_can_be_locked_out_after_10_unsuccessful_attempts
    logout!

    visit "/login"

    11.times do
      within("form#login-form") do
        fill_in "Email", with: "alice@example.com"
        fill_in "Password", with: "wrong_password"
        click_on "Login"
      end
    end

    assert_current_path "/login"
    assert_css ".alert-danger"
    assert_content "This account is currently locked out and cannot be logged in to"
    assert_content :all, "Request Account Unlock"

    visit "/login"
    within("form#login-form") do
      fill_in "Email", with: "alice@example.com"
      fill_in "Password", with: "foobar"
      click_on "Login"
    end

    assert_current_path "/login"
    assert_content "This account is currently locked out and cannot be logged in to"
    assert_css ".alert-danger"
    assert_content :all, "Request Account Unlock"
  end

  def test_account_can_be_unlocked_with_magic_link
    logout!

    visit "/login"

    11.times do
      within("form#login-form") do
        fill_in "Email", with: "alice@example.com"
        fill_in "Password", with: "wrong_password"
        click_on "Login"
      end
    end

    assert_current_path "/login"
    assert_css ".alert-danger"
    assert_content "This account is currently locked out and cannot be logged in to"
    assert_content :all, "Request Account Unlock"

    click_on "Request Account Unlock"
    assert_equal 1, mails_count

    assert_match(/<a href='http:\/\/www\.example\.com\/unlock-account\?key=/, mail_body(0))
    assert_equal @alice_account.id, DB[:account_lockouts].first[:id]

    unlock_account_key = /<a href='http:\/\/www\.example\.com\/unlock-account\?key=([\w|-]+)' method='post'>/i.match(mail_body(0))[1]

    visit "/unlock-account?key=#{unlock_account_key}"
    assert_current_path "/unlock-account"
    click_on "Unlock Account"
    assert_current_path "/entries/new"
    assert_css ".alert-success"
    assert_content "Your account has been unlocked"
    assert_link "Alice"
  end
end

class UnverifiedAccountManagementTest < CapybaraTestCase
  include GenericAccountManagmentActionsTests

  def before_all
    super
    clean_test_db!
    @alice_account = create_account!
    @test_account_status = 1
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      clean_mailbox
      login!
      super
    end
  end

  def test_user_unverified_user_can_change_password
    new_password = "barfoo"
    visit "/change-password"
    fill_in "password", with: "foobar"
    fill_in "new-password", with: new_password
    fill_in "password-confirm", with: new_password
    click_on "Change Password"

    assert BCrypt::Password.new(Account[@alice_account.id].password_hash) == "barfoo"
    assert_current_path "/account"
    assert_css ".alert-success"
    assert_content "Your password has been changed"
  end
end

class VerifiedAccountManagementTest < CapybaraTestCase
  include GenericAccountManagmentActionsTests

  def before_all
    super
    clean_test_db!
    @alice_account = create_and_verify_account!
    @test_account_status = 2
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      clean_mailbox
      login!
      super
    end
  end

  def test_can_verify_account
    test_account = create_account!(user_name: "test user", email: "test_user@example.com")
    login!(email: "test_user@example.com")
    assert_equal 2, mails_count # One for the verify account and one for the admin notification of account creation
    assert_match(/<a href='https:\/\/www\.example\.com\/verify-account\?key=/, verify_account_mail_body)
    assert_equal test_account.id, DB[:account_verification_keys].first[:id]

    verify_account_key = /<a href='https:\/\/www\.example\.com\/verify-account\?key=([\w|-]+)'>/i.match(verify_account_mail_body)[1]

    visit "/verify-account?key=#{verify_account_key}"
    assert_current_path "/verify-account"
    click_on "Verify Account"
    assert_current_path "/entries/new"
    assert_css ".alert-success"
    assert_content "Your account has been verified"
    assert_link "test user"
  end

  def test_send_a_new_verify_account_email_if_first_has_expired
    test_account = create_account!(user_name: "test user", email: "test_user@example.com", password: "foobar")
    assert_equal 2, mails_count # One for the verify account and one for the admin notification of account creation
    logout!

    assert_equal 1, DB[:account_verification_keys].all.count
    assert_equal test_account.id, DB[:account_verification_keys].first[:id]
    # Hack to simulate an account not verified during grace period
    DB[:account_verification_keys].update(requested_at: Time.now - (60 * 60 * 24 * 4))
    DB[:account_verification_keys].update(email_last_sent: Time.now - (60 * 60 * 24 * 3))
    hacked_email_last_sent = DB[:account_verification_keys].first[:email_last_sent]

    visit "/"
    assert_current_path "/login"

    login!(email: "test_user@example.com", password: "foobar")

    assert_css ".alert-danger"
    assert_content "The account you tried to login with is currently awaiting verification"
    click_on "Send Verification Email Again"

    assert_equal 3, mails_count

    assert_current_path "/login"
    assert_css ".alert-success"

    refute_equal hacked_email_last_sent, DB[:account_verification_keys].first[:email_last_sent]

    assert_match(/<a href='http:\/\/www\.example\.com\/verify-account\?key=/, last_mail_body)
    assert_equal Account[test_account.id].id, DB[:account_verification_keys].first[:id]

    verify_account_key = /<a href='http:\/\/www\.example\.com\/verify-account\?key=([\w|-]+)'>/i.match(last_mail_body)[1]

    visit "/verify-account?key=#{verify_account_key}"
    assert_current_path "/verify-account"
    click_on "Verify Account"
    assert_current_path "/entries/new"
    assert_css ".alert-success"
    assert_content "Your account has been verified"
    assert_link "test user"
  end

  def test_request_password_reset_does_not_send_email_to_unknown_account
    logout!

    visit "/"
    click_on "Forgot Password?"
    assert_current_path "/reset-password-request"
    fill_in "Email", with: "notregistered@example.com"
    click_on "Password Reset"

    assert_current_path "/reset-password-request"
    assert_css ".alert-danger"
    assert_content "There was an error requesting a password reset"
    assert_equal 0, mails_count
  end

  def test_request_password_reset_with_valid_account
    logout!

    visit "/"
    click_on "Forgot Password?"

    assert_current_path "/reset-password-request"
    fill_in "Email", with: "alice@example.com"
    click_on "Password Reset"

    assert_current_path "/login"
    assert_content "An Email has been sent to reset your password"
    assert_equal 1, mails_count
    assert_match(/<a href='http:\/\/www\.example\.com\/reset-password\?key=/, mail_body(0))
    assert_equal @alice_account.id, DB[:account_password_reset_keys].first[:id]

    reset_password_key = /<a href='http:\/\/www\.example\.com\/reset-password\?key=([\w|-]+)' method='post'>/i.match(mail_body(0))[1]

    visit "/reset-password?key=#{reset_password_key}"

    assert_current_path "/reset-password"

    fill_in "Password", with: "supersecret"
    fill_in "Confirm Password", with: "supersecret"
    click_on "Reset Password"

    assert_current_path "/entries"
    assert_content "Your password has been reset"
    assert_content "Alice"

    assert_equal 2, mails_count
    assert_match "You recently requested a password reset,", mail_body(1)

    logout!

    visit "/login"

    within("form#login-form") do
      fill_in "Email", with: "alice@example.com"
      fill_in "Password", with: "foobar" # Old Password
      click_on "Login"
    end

    assert_current_path "/login"
    assert_content "There was an error logging in"

    within("form#login-form") do
      fill_in "Email", with: "alice@example.com"
      fill_in "Password", with: "supersecret"
      click_on "Login"
    end

    assert_current_path "/entries/new" # Test user has no entry for current day
    assert_content "You have been logged in"
  end

  def test_user_get_an_email_when_changing_password
    new_password = "supersecret"
    visit "/change-password"
    fill_in "password", with: "foobar"
    fill_in "new-password", with: new_password
    fill_in "password-confirm", with: new_password
    click_on "Change Password"

    assert_equal 1, mails_count

    assert_match(/Your Password has been changed/, mail_body(0))
  end

  def test_user_can_change_email
    new_email = "aliceinwonderland@example.com"

    visit "/change-login"
    fill_in "login", with: new_email
    fill_in "password", with: "foobar"
    click_on "Change Email"

    assert_equal "alice@example.com", Account[@alice_account.id].email
    assert_current_path "/account"
    assert_css ".alert-success"
    assert_content "alice@example.com"
    assert_content "An email has been sent to your new email verify it"

    assert_equal 1, mails_count

    assert_equal mail_to(0), new_email # Check email is sent to the new address
    assert_match(/<a href='http:\/\/www\.example\.com\/verify-login-change\?key=/, mail_body(0))
    assert_equal @alice_account.id, DB[:account_login_change_keys].first[:id]

    verify_login_change_key = /<a href='http:\/\/www\.example\.com\/verify-login-change\?key=([\w|-]+)' method='post'>/i.match(mail_body(0))[1]

    visit "/verify-login-change?key=#{verify_login_change_key}"

    assert_current_path "/verify-login-change"

    click_on "Verify Email Change"

    assert_current_path "/entries/new"
    assert_css ".alert-success"
    assert_content "Your new email has been verified"
    assert_content "Alice"

    logout!

    visit "/login"

    within("form#login-form") do
      fill_in "Email", with: "alice@example.com" # Old email
      fill_in "Password", with: "foobar"
      click_on "Login"
    end

    assert_current_path "/login"
    assert_content "There was an error logging in"

    within("form#login-form") do
      fill_in "Email", with: new_email
      fill_in "Password", with: "foobar"
      click_on "Login"
    end

    assert_current_path "/entries/new" # Test User has no entry for current day
    assert_content "You have been logged in"
  end
end

class TwoFactorAuthenticationTest < CapybaraTestCase
  def before_all
    super
    clean_test_db!
    @alice_account = create_and_verify_account!
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      login!
      super
    end
  end

  def test_can_activate_two_factor_authentication
    visit "/account"

    assert_content "Setup 2FA"
    refute_content "View Recovery Codes"
    refute_content "Disable 2FA"

    click_on "Setup 2FA"

    assert_current_path "/otp-setup"
    assert_link "Back to Account", href: "/account"
    assert_css("#qrcode-otp")

    secret = page.find("#otp-secret-key").text

    totp = ROTP::TOTP.new(secret)

    fill_in "Password", with: "foobar"
    fill_in "Authentication Code", with: totp.now

    click_on "Setup TOTP Authentication"
    assert_equal 16, DB[:account_recovery_codes].where(id: @alice_account.id).all.size

    assert_current_path "/entries/new"
    assert_css ".alert-success"
    assert_content "TOTP authentication is now setup"
    assert_link "Alice", href: "#" # Bootstrap navbar collapse link

    visit "/account"
    refute_content "Setup 2FA"
    assert_content "View Recovery Codes"
    assert_content "Disable 2FA"
  end

  def test_can_see_recovery_codes
    setup_two_fa!(@alice_account.id)

    visit "/account"
    click_on "View Recovery Codes"
    assert_current_path "/recovery-codes"
    fill_in "Password", with: "foobar"
    click_on "View Authentication Recovery Codes"

    assert_current_path "/recovery-codes"
    assert_link "Back to Account", href: "/account"
    assert_content "Print"
    assert_content "Copy"

    recovery_codes = DB[:account_recovery_codes].where(id: @alice_account.id).map(:code)
    recovery_codes.each do |code|
      assert_content code
    end
  end

  def test_can_add_recovery_code
    setup_two_fa!(@alice_account.id)
    logout!
    login!

    assert_current_path "/multifactor-auth"
    click_on "Authenticate Using Recovery Code"
    assert_current_path "/recovery-auth"

    recovery_code = DB[:account_recovery_codes].where(id: @alice_account.id).first[:code]

    fill_in "Recovery Code", with: recovery_code
    click_on "Authenticate via Recovery Code"

    assert_equal 15, DB[:account_recovery_codes].where(id: @alice_account.id).all.size

    visit "/account"
    click_on "View Recovery Codes"

    assert_current_path "/recovery-codes"
    fill_in "Password", with: "foobar"
    click_on "View Authentication Recovery Codes"

    assert_current_path "/recovery-codes"
    refute_content recovery_code
    assert_content "Refill your recovery codes ?"

    fill_in "Password", with: "foobar"
    click_on "Add Authentication Recovery Codes"

    assert_equal 16, DB[:account_recovery_codes].where(id: @alice_account.id).all.size
    assert_css ".alert-success"
    assert_content "Additional authentication recovery codes have been added"
  end

  def test_can_disable_two_factors_authentication
    visit "/account"
    click_on "Setup 2FA"
    secret = page.find("#otp-secret-key").text
    totp = ROTP::TOTP.new(secret)
    fill_in "Password", with: "foobar"
    fill_in "Authentication Code", with: totp.now
    click_on "Setup TOTP Authentication"
    logout!

    login!

    click_on "Authenticate Using Recovery Code"

    recovery_code = DB[:account_recovery_codes].where(id: @alice_account.id).first[:code]

    fill_in "Recovery Code", with: recovery_code
    click_on "Authenticate via Recovery Code"

    visit "/account"

    click_on "Disable 2FA"

    assert_current_path "/multifactor-disable"
    assert_link "Back to Account", href: "/account"

    fill_in "Password", with: "foobar"
    click_on "Remove 2FA"

    assert_css ".alert-success"
    assert_content "All multifactor authentication methods have been disabled"
    assert_link "Alice", href: "#" # Bootstrap navbar collapse link
    assert_current_path "/account"

    assert_equal 0, DB[:account_recovery_codes].where(id: @alice_account.id).all.size
    assert_equal 0, DB[:account_otp_keys].where(id: @alice_account.id).all.size
  end
end
