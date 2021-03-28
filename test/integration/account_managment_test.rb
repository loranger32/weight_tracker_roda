require_relative "../test_helpers"

class AccountManagementTest < CapybaraTestCase
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

    visit "/accounts/security_log"

    assert_current_path "/accounts/security_log"
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

  def test_close_account
    # Need to decide what to do when closing account : simply disabling or delete account completely
    skip
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

    check "I have backed up my data"
    
    fill_in "password", with: "foobar"
    click_on "Close Account"
  end
end