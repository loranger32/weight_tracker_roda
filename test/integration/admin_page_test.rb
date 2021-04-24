require_relative "../test_helpers"

class AccountManagementTest < CapybaraTestCase
  def setup
    DB[:accounts].delete
    DB.reset_primary_key_sequence(:accounts)
  end

  def test_non_admin_user_cannot_access_admin_page
    create_and_verify_account!
  
    alice_account = Account.first
    alice_account.id = 2
    Account.first.delete
    alice_account.save
    assert_equal 2, Account.first.id

    visit "/admin/accounts"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"
  end

  def test_admin_without_two_fa_cannot_access_admin_page
    # Create account and make sure it has 1 as id (temporary hack to designate admin)
    
    create_and_verify_account!
    alice_account = Account.first
    assert_equal 1, alice_account.id
    
    visit "/admin/accounts"

    assert_current_path "/otp-setup"
    refute_content "Admin Panel"
  end

  def test_admin_with_2_fa_enabled_can_access_admin_page
    create_and_verify_account!
    setup_two_fa!
    
    alice_account = Account.first
    assert_equal 1, alice_account.id
    
    visit "/admin/accounts"
    
    assert_current_path "/admin/accounts"    
  end
end
