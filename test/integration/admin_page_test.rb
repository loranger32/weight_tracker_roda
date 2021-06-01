require_relative "../test_helpers"

class AdminPageTest < CapybaraTestCase
  def load_fixtures
    DB[:accounts].insert(user_name: "test unverified account", email: "test.unverified@example.com",
                         password_hash: BCrypt::Password.create("secret", cost: 2),
                         status_id: 1)
    DB[:accounts].insert(user_name: "test verified account", email: "test.verified@example.com",
                         password_hash: BCrypt::Password.create("secret", cost: 2),
                         status_id: 2)
    DB[:accounts].insert(user_name: "test closed account", email: "test.closed@example.com",
                         password_hash: BCrypt::Password.create("secret", cost: 2),
                         status_id: 3)
  end

  def clean_fixtures
    DB[:accounts].delete
    DB.reset_primary_key_sequence(:accounts)
  end

  def test_non_admin_user_cannot_access_admin_page
    create_and_verify_account!
    
    visit "/admin"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"
    
    visit "/admin/accounts"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"
  end

  def test_admin_without_two_fa_cannot_access_admin_page
    create_and_verify_account!

    alice_account = Account.where(user_name: "Alice").first
    Admin.new(account_id: alice_account.id).save
    
    visit "/admin"

    assert_current_path "/otp-setup"
    refute_content "Admin Panel"
  end

  def test_admin_with_2_fa_enabled_can_access_admin_page
    create_and_verify_account!
    alice_account = Account.where(user_name: "Alice").first
    setup_two_fa!(alice_account.id)

    Admin.new(account_id: alice_account.id).save

    visit "/admin"
    
    assert_current_path "/admin/accounts"
    assert_content "Admin Panel"
    assert_content "Admin - Alice"
    assert_link "All"   
    assert_link "Verified"   
    assert_link "Unverified"   
    assert_link "Closed"   
    assert_link "OTP ON"   
    assert_link "OTP OFF"
    assert_link "ADMIN"
    assert_link "Delete", count: 4

    assert_content "alice@example.com"
    assert_content "test.unverified@example.com"
    assert_content "test.verified@example.com"   
    assert_content "test.closed@example.com"
    assert_content "test unverified account"
    assert_content "test verified account"
    assert_content "test closed account"

    click_on "Verified"
    assert_content "alice@example.com"
    assert_content "test.verified@example.com"   
    assert_content "test verified account"
    refute_content "test.unverified@example.com"
    refute_content "test.closed@example.com"
    refute_content "test unverified account"
    refute_content "test closed account"

    click_on "Unverified"
    refute_content "alice@example.com"
    assert_content "test.unverified@example.com"
    refute_content "test.verified@example.com"   
    refute_content "test.closed@example.com"
    assert_content "test unverified account"
    refute_content "test verified account"
    refute_content "test closed account"

    click_on "Closed"
    refute_content "alice@example.com"
    refute_content "test.unverified@example.com"
    refute_content "test.verified@example.com"   
    assert_content "test.closed@example.com"
    refute_content "test unverified account"
    refute_content "test verified account"
    assert_content "test closed account"    

    click_on "OTP ON"
    assert_content "alice@example.com"
    refute_content "test.unverified@example.com"
    refute_content "test.verified@example.com"   
    refute_content "test.closed@example.com"
    refute_content "test unverified account"
    refute_content "test verified account"
    refute_content "test closed account"

    click_on "OTP OFF"
    refute_content "alice@example.com"
    assert_content "test.unverified@example.com"
    assert_content "test.verified@example.com"   
    assert_content "test.closed@example.com"
    assert_content "test unverified account"
    assert_content "test verified account"
    assert_content "test closed account"

    click_on "ADMIN"
    assert_content "alice@example.com"
    refute_content "test.unverified@example.com"
    refute_content "test.verified@example.com"   
    refute_content "test.closed@example.com"
    refute_content "test unverified account"
    refute_content "test verified account"
    refute_content "test closed account"
  end

  def test_admin_can_delete_a_non_admin_account
    # This test is slightly flawed because it deletes an account that has been
    # directly inserted in the DB, and has no rows in other Rodauth tables
    create_and_verify_account!
    alice_account = Account.where(user_name: "Alice").first
    setup_two_fa!(alice_account.id)

    Admin.new(account_id: alice_account.id).save

    visit "/admin"
    assert_current_path "/admin/accounts"
    verified_account = Account.where(user_name: "test verified account").first
    click_link "Delete", href: "/admin/accounts/delete?account_id=#{verified_account.id}"

    assert_current_path "/admin/accounts/delete?account_id=#{verified_account.id}"
    assert_content "Admin Panel"
    assert_content "Admin - Alice"

    assert_content "Delete Account"
    assert_content "test verified account"
    assert_content "test.verified@example.com"
    assert_content "0 batches"
    assert_content "0 entries"
    assert_content "Last entry: /"

    click_on "Delete Account"

    assert_current_path "/admin/accounts"
    assert_css ".flash-notice"
    assert_content "Account successfully deleted"
    refute_content "test verified account"
    refute_content "test.verified@example.com"
    refute_link "Delete", href: "/admin/accounts/delete?account_id=#{verified_account.id}"
  end

  def test_admin_cannot_delete_an_admin_account
    create_and_verify_account!
    alice_account = Account.where(user_name: "Alice").first
    setup_two_fa!(alice_account.id)

    Admin.new(account_id: alice_account.id).save

    visit "/admin"

    click_link "Delete", href: "/admin/accounts/delete?account_id=#{alice_account.id}"
    assert_current_path "/admin/accounts"
    assert_css ".flash-error"
    assert_content "Cannot delete an admin user"
  end
end
