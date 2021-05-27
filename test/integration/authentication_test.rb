require_relative "../test_helpers"

class AuthenticationTest < CapybaraTestCase
  def test_user_is_redirected_to_login_page_if_not_signed_in
    restricted_pathes = %w[/ /accounts/1 /security-log /entries /entries/new
                           /change-login /change-password /change-user-name /export-data
                           /close-account /admin/accounts]
    
    restricted_pathes.each do |path|
      visit path
      assert_current_path "/login"
      assert_title "WT - Log In"
      assert_css ".flash-error"  
    end
  end

  def test_user_can_create_an_account
    visit "/create-account"
    fill_in "user_name", with: "Alice"
    fill_in "login", with: "alice@example.com"
    fill_in "login-confirm", with: "alice@example.com"
    fill_in "password", with: "foobar"
    fill_in "password-confirm", with: "foobar"
    click_on "Create Account"
    assert_current_path "/entries/new"
    assert_css ".flash-notice"
    assert_content "Alice"
  end

  def test_user_can_login
    create_and_verify_account!
    logout!
    login!

    assert_current_path "/entries/new" # Test User has no entry for current day
    assert_css ".flash-notice"
    assert_content "Alice"
  end

  def test_user_can_logout
    create_and_verify_account!
    logout!
    assert_current_path "/login"
    assert_css ".flash-notice"
    assert_content "You have been logged out"
  end

  def test_can_authenticate_with_two_factor_authentication
    create_and_verify_account!
    account_id = Account.first.id
    visit "/account"
    click_on "Setup 2FA"
    secret = page.find("#otp-secret-key").text
    totp = ROTP::TOTP.new(secret)
    fill_in "Password", with: "foobar"
    fill_in "Authentication Code", with: totp.now
    click_on "Setup TOTP Authentication"
    logout!

    login!

    assert_current_path "/multifactor-auth"

    assert_link "Authenticate Using TOTP", href: "/otp-auth"
    assert_link "Authenticate Using Recovery Code", href: "/recovery-auth"

    click_on "Authenticate Using TOTP"

    assert_current_path "/otp-auth"
    assert_content "Authentication Code"
    refute_content "Alice"

    # Hack the "Preventing reuse of Time based OTP's" mechanism
    last_use_time_stamp = DB[:account_otp_keys].where(id: account_id).first[:last_use]
    DB[:account_otp_keys].where(id: account_id).update(last_use: last_use_time_stamp - 60)

    fill_in "Authentication Code", with: totp.now
    click_on "Authenticate Using TOTP"
    
    assert_current_path "/entries/new"
    assert_link "Alice", href: "/account"
    assert_css ".flash-notice"
    assert_content "You have been multifactor authenticated"
  end

  def test_can_authenticate_with_recovery_codes
    create_and_verify_account!
    account_id = Account.first.id
    visit "/account"
    click_on "Setup 2FA"
    secret = page.find("#otp-secret-key").text
    totp = ROTP::TOTP.new(secret)
    fill_in "Password", with: "foobar"
    fill_in "Authentication Code", with: totp.now
    click_on "Setup TOTP Authentication"
    logout!

    login!

    assert_current_path "/multifactor-auth"

    assert_link "Authenticate Using TOTP", href: "/otp-auth"
    assert_link "Authenticate Using Recovery Code", href: "/recovery-auth"

    click_on "Authenticate Using Recovery Code"

    assert_current_path "/recovery-auth"
    assert_content "Recovery Code"
    refute_content "Alice"

    recovery_code = DB[:account_recovery_codes].where(id: account_id).first[:code]

    fill_in "Recovery Code", with: recovery_code
    click_on "Authenticate via Recovery Code"

    assert_current_path "/entries/new"
    assert_link "Alice", href: "/account"
    assert_css ".flash-notice"
    assert_content "You have been multifactor authenticated"

    assert_equal 15, DB[:account_recovery_codes].where(id: account_id).all.size
  end
end
