require_relative "../test_helpers"

class AuthenticationTest < CapybaraTestCase
  def test_user_is_redirected_to_login_page_if_not_signed_in
    restricted_pathes = %w[/ /accounts/1 /security-log /entries /entries/new
                           /change-login /change-password /change-user-name /export-data
                           /close-account]
    
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

    assert_current_path "/entries"
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
end
