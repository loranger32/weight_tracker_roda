require_relative "../test_helpers"

class AccountManagementTest < CapybaraTestCase
  def test_user_can_visit_account_page
    login!
    account = Account.first

    visit "/accounts/#{account.id}"
    assert_current_path "/accounts/#{account.id}"
    assert_content account.user_name, count: 2
    assert_content account.email, count: 1
    assert_link "Change User Name"
    assert_link "Change Email"
    assert_link "Change Password"
    assert_link "Security Log"
    assert_link "Export Data"
    assert_button "Log Out"
    assert_link "Close Account"
  end
  
  def test_user_can_change_user_name
    new_user_name = "Alice In Wonderland"
    login!
    visit "/change-user-name"
    fill_in "user_name", with: new_user_name
    fill_in "password", with: "foobar"
    click_on "Change User Name"

    account = Account.first

    assert_equal new_user_name, account.user_name
    assert_current_path "/accounts/#{account.id}"
    assert_css ".flash-notice"
    assert_content new_user_name
  end

  def test_user_can_change_email
    new_email = "aliceinwonderland@example.com"
    login!
    visit "/change-login"
    fill_in "login", with: new_email
    fill_in "login-confirm", with: new_email
    fill_in "password", with: "foobar"
    click_on "Change Email"

    account = Account.first

    assert_equal new_email, account.email 
    assert_current_path "/accounts/#{account.id}"
    assert_css ".flash-notice"
    assert_content new_email
  end

  def test_user_can_change_password
    new_password = "barfoo"
    login!
    visit "/change-password"
    fill_in "password", with: "foobar"
    fill_in "new-password", with: new_password
    fill_in "password-confirm", with: new_password
    click_on "Change Password"

    account = Account.first

    assert BCrypt::Password.new(account.password_hash) == "barfoo" 
    assert_current_path "/accounts/#{account.id}"
    assert_css ".flash-notice"
    assert_content "Your password has been changed"
  end

  def test_security_log
    create_account!
    logout!
    login!
    logout!
    visit "/login"
    fill_in "login", with: "alice@example.com"
    fill_in "password", with: "wrongpassword"
    click_on "Log In"
    login!

    visit "/security-log"

    assert_current_path "/security-log"
    assert_content "Review the access to your account"
    assert_content "create_account", count: 1
    assert_content /\slogin\s/, count: 2
    assert_content "logout", count: 2
    assert_content "login_failure", count: 1
  end

  def test_export_data_page
    login!
    visit "/export-data"

    assert_current_path "/export-data"
    assert_content "Export Data"
    assert_content "json"
    assert_content "csv"
    assert_content "xml"

    assert_selector "label", count: 3
    assert_selector "input", count: 4
  end

  def test_cancel_button_behavior
    visit "/create-account"
    click_on "Cancel"
    assert_current_path "/login"

    login!
    visit "/change-user-name"
    click_on "Cancel"
    assert_current_path "/accounts/#{Account.first.id}"

    login!
    visit "/change-login"
    click_on "Cancel"
    assert_current_path "/accounts/#{Account.first.id}"

    login!
    visit "/change-password"
    click_on "Cancel"
    assert_current_path "/accounts/#{Account.first.id}"

    login!
    visit "/export-data"
    click_on "Cancel"
    assert_current_path "/accounts/#{Account.first.id}"
  end

  def run_test_export_data_for_file_format(file_format)
    pre_existing_data_files = Dir.glob("tmp/wt_data_Alice_*.#{file_format}")
    
    login!
    visit "/export-data"
    choose file_format
    click_on "Download"

    existing_data_files = Dir.glob("tmp/wt_data_Alice_*.#{file_format}")

    assert_equal pre_existing_data_files.size + 1, existing_data_files.size
    
    FileUtils.remove_entry_secure((existing_data_files - pre_existing_data_files)[0])
  end

  def test_export_data_to_json
    run_test_export_data_for_file_format("json")
  end

  def test_export_data_to_csv
    run_test_export_data_for_file_format("csv")
  end

  def test_export_data_to_xml
    run_test_export_data_for_file_format("xml")
  end

  def test_close_account_page
    login!
    visit "/close-account"
    assert_current_path "/close-account"

    click_on "Take me to the export data page"
    assert_current_path "/export-data"

    visit "/close-account"
    click_on "I don't want to close my account"
    assert_current_path "/accounts/#{Account.first.id}"

    visit "/close-account"
    refute_checked_field "I have backed up my data"
    assert_css ".btn-disabled"
  end

  def test_cannot_close_account_if_checkbox_is_not_checked
    login!

    assert_equal 2, Account.first.status_id

    visit "/close-account"

    fill_in "password", with: "foobar"
    click_on "Close Account"

    assert_current_path "/close-account"
    assert_css ".flash-error"
    assert_content "You did not confirm you made a backup of your data"

    assert_equal 2, Account.first.status_id
  end

  def test_can_close_account_if_checkbox_is_checked
    login!

    assert_equal 2, Account.first.status_id
    
    visit "/close-account"

    check "I have backed up my data"
    fill_in "password", with: "foobar"
    click_on "Close Account"

    assert_current_path "/login"

    assert_equal 3, Account.first.status_id

    fill_in "Email", with: "Alice"
    fill_in "Password", with: "foobar"
    click_on "Log In"

    assert_current_path "/login"
    assert_css ".flash-error"
  end
end

class AccountManagementMailTest < CapybaraTestCase
  def mails_count
    Mail::TestMailer.deliveries.length
  end

  def mail_body(mail_index)
    Mail::TestMailer.deliveries[mail_index].body.raw_source
  end

  def teardown
    Mail::TestMailer.deliveries.clear
  end

  def test_request_password_does_not_send_email_to_unknown_account
    visit "/"
    click_on "Reset Password"
    assert_current_path "/reset-password-request"
    fill_in "Email", with: "notregistered@example.com"
    click_on "Password Reset"

    assert_current_path "/reset-password-request"
    assert_content "There was an error requesting a password reset"
    assert_equal 0, mails_count
  end

  def test_request_password_change_with_valid_account
    create_account!
    logout!
    visit "/"
    click_on "Reset Password"

    assert_current_path "/reset-password-request"
    fill_in "Email", with: "alice@example.com"
    click_on "Password Reset"

    assert_current_path "/login"
    assert_content "An Email has been sent to reset your password"
    assert_equal 1, mails_count
    assert_match(/<a href='http:\/\/www\.example\.com\/reset-password\?key=/, mail_body(0))
    assert_equal Account.first.id, DB[:account_password_reset_keys].first[:id]
    
    reset_password_key = /<a href='http:\/\/www\.example\.com\/reset-password\?key=([\w|-]+)' method='post'>/i.match(mail_body(0))[1]

    visit "/reset-password?key=#{reset_password_key}"

    assert_current_path "/reset-password"

    fill_in "Password", with: "supersecret"
    fill_in "Confirm Password", with: "supersecret"
    click_on "Reset Password"

    assert_current_path "/entries"
    assert_content "Your password has been reset"
    assert_content "Alice"

    logout!

    visit "/login"

    fill_in "Email", with: "alice@example.com"
    fill_in "Password", with: "foobar" # Old Password
    click_on "Log In"

    assert_current_path "/login"
    assert_content "There was an error logging in"

    fill_in "Email", with: "alice@example.com"
    fill_in "Password", with: "supersecret"
    click_on "Log In"

    assert_current_path "/entries"
    assert_content "You have been logged in"
  end
end
