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
    DB[:admins].delete
    DB.reset_primary_key_sequence(:admins)
    DB[:accounts].delete
    DB.reset_primary_key_sequence(:accounts)
  end

  def setup_admin
    alice_account = create_and_verify_account!
    setup_two_fa!(alice_account.id)
    Admin.new(account_id: alice_account.id).save
    alice_account.reload
  end

  def test_non_admin_user_cannot_access_admin_pages
    alice_account = create_and_verify_account!
    
    visit "/admin"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"
    
    visit "/admin/accounts"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"

    visit "/admin/accounts/verify?account_id=#{alice_account.id}"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"
    
    visit "/admin/accounts/delete?account_id=#{alice_account.id}"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"

    assert_raises Roda::RodaPlugins::RouteCsrf::InvalidToken do
      post "/admin/accounts/delete?account_id=#{alice_account.id}"
    end

    assert_raises Roda::RodaPlugins::RouteCsrf::InvalidToken do
      post "/admin/accounts/verify?account_id=#{alice_account.id}"
    end
  end

  def test_admin_without_two_fa_cannot_access_admin_page
    account = create_and_verify_account!(user_name: "admin", email: "admin@example.com")
    Admin.new(account_id: account.id).save

    visit "/admin"

    assert_current_path "/otp-setup"
    refute_content "Admin Panel"
  end

  def test_admin_with_2_fa_enabled_can_access_admin_page
    alice_account = setup_admin

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
    assert_link "Delete", count: 3
    assert_link "Verify", count: 1

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
    soon_deleted_account = create_and_verify_account!(user_name: "soon deleted",
                                                      email: "soondeleted@example.com")
    batch_id = soon_deleted_account.active_batch_id
    entry = Entry.new(weight: "60.0", day: "2021-06-01", note: "",
                      account_id: soon_deleted_account.id, batch_id: batch_id).save
    
    logout!(soon_deleted_account)
    
    alice_account = setup_admin
    
    visit "/admin"
    assert_current_path "/admin/accounts"
    
    click_link "Delete", href: "/admin/accounts/delete?account_id=#{soon_deleted_account.id}"

    assert_current_path "/admin/accounts/delete?account_id=#{soon_deleted_account.id}"
    assert_content "Admin Panel"
    assert_content "Admin - Alice"

    assert_content "Delete Account"
    assert_content "soon deleted"
    assert_content "soondeleted@example.com"
    assert_content "1 batches" # The default one
    assert_content "1 entries"
    assert_content "Last entry: 01 Jun 2021"

    click_on "Delete Account"

    assert_current_path "/admin/accounts"
    assert_css ".flash-notice"
    assert_content "Account successfully deleted"
    refute_content "soon deleted"
    refute_content "soondeleted@example.com"
    refute_link "Delete", href: "/admin/accounts/delete?account_id=#{soon_deleted_account.id}"
  end

  def test_admin_cannot_delete_an_admin_account
    alice_account = setup_admin
    visit "/admin"
    refute_link "Delete", href: "/admin/accounts/delete?account_id=#{alice_account.id}"

    assert_raises Roda::RodaPlugins::RouteCsrf::InvalidToken do
      post "/admin/accounts/delete?account_id=#{alice_account.id}"
    end
  end

  def test_admin_can_verify_an_account
    unverified_account = create_account!(user_name: "unverified", email: "unverified@example.com")
    logout!(unverified_account)

    alice_account = setup_admin

    visit "/admin"
    click_link "Verify", href: "/admin/accounts/verify?account_id=#{unverified_account.id}"
    assert_current_path "/admin/accounts/verify?account_id=#{unverified_account.id}"
    assert_content "Admin Panel"
    assert_content "Admin - Alice"
    assert_content "Verify Account"
    assert_content "You are about to manually verify this account."
    assert_content "unverified"
    assert_content "unverified@example.com"
    assert_content "1 batches"
    assert_content "0 entries"
    assert_content "Last entry: /"

    click_on "Verify Account"
    assert_current_path "/admin/accounts"
    assert_css ".flash-notice"
    assert_content "Account successfully verified"
    assert_content "unverified"
    assert_content "unverified@example.com"
    refute_link "Verify", href: "/admin/accounts/verify?account_id=#{unverified_account.id}"

    assert unverified_account.reload.is_verified?
    assert_nil DB[:account_verification_keys].where(id: unverified_account.id).first
  end
end
