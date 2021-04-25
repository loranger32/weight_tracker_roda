require_relative "../test_helpers"

class AccountManagementTest < CapybaraTestCase
  def test_non_admin_user_cannot_access_admin_page
    create_and_verify_account!
  
    visit "/admin/accounts"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"
  end

  def test_admin_without_two_fa_cannot_access_admin_page
    create_and_verify_account!    
    Admin.new(account_id: Account.first.id).save
    
    visit "/admin/accounts"

    assert_current_path "/otp-setup"
    refute_content "Admin Panel"
  end

  def test_admin_with_2_fa_enabled_can_access_admin_page
    create_and_verify_account!
    setup_two_fa!
  
    Admin.new(account_id: Account.first.id).save
    
    DB[:accounts].insert(user_name: "test user", email: "test@example.com",
                         password_hash: BCrypt::Password.create("secret", cost: 2),
                         status_id: 2)

    visit "/admin/accounts"
    
    assert_current_path "/admin/accounts"
    assert_content "Admin Panel"
    assert_content "Admin - Alice"
    assert_link "All"   
    assert_link "Verified"   
    assert_link "Unverified"   
    assert_link "Closed"   
    assert_link "OTP ON"   
    assert_link "OTP OFF"

    assert_content "alice@example.com"   
    assert_content "test@example.com"   
    assert_content "test user"   
  end
end
