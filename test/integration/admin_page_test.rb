require_relative "../test_helpers"

class AccountManagementTest < CapybaraTestCase
  def test_non_admin_user_cannot_access_admin_pages
    create_and_verify_account!

    visit "/admin/accounts"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"
  end
end