require_relative "../test_helpers"

class AuthenticationTest < CapybaraTestCase
  def test_user_is_redirected_to_login_page_if_not_signed_in
    restricted_pathes = %w[/ /accounts/1 /accounts/security_log /entries /entries/new
                           /change-login /change-password /change-user-name /export-data
                           close-account]
    
    restricted_pathes.each do |path|
      visit path
      assert_current_path "/login"
      assert_title "WT - Log In"
      assert page.has_css? ".flash-error"  
    end
  end

  def test_user_can_create_an_account
    create_account!
    assert page.has_css? ".flash-notice"
    assert page.has_content? "Alice"
    assert_equal "/entries/new", page.current_path
  end

  def test_user_can_login
    login!
    assert page.has_css? ".flash-notice"
    assert page.has_content? "Alice"
    assert_current_path "/entries"
  end

  def test_user_can_logout
    login!
    visit "/"
    logout!
    assert_current_path "/login"
    assert page.has_css?(".flash-notice")
    assert page.has_content? "You have been logged out"
  end
end