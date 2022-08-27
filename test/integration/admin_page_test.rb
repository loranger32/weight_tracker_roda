require_relative "../test_helpers"

class AdminPageTest < CapybaraTestCase
  def load_fixtures
    DB[:accounts].insert(user_name: "test unverified account", email: "test.unverified@example.com",
      password_hash: BCrypt::Password.create("secret", cost: 2), status_id: 1)
    DB[:accounts].insert(user_name: "test verified account", email: "test.verified@example.com",
      password_hash: BCrypt::Password.create("secret", cost: 2), status_id: 2)
    DB[:accounts].insert(user_name: "test closed account", email: "test.closed@example.com",
      password_hash: BCrypt::Password.create("secret", cost: 2), status_id: 3)
  end

  def before_all
    super
    clean_test_db!
    load_fixtures
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      super
    end
  end

  def setup_admin
    alice_account = create_account!
    app.rodauth.verify_account(account_id: alice_account.id)
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

    visit "/admin/accounts/close?account_id=#{alice_account.id}"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"

    visit "/admin/accounts/open?account_id=#{alice_account.id}"
    assert_equal 403, status_code
    assert_content "403 ERROR"
    refute_content "Admin Panel"

    assert_raises Roda::RodaPlugins::RouteCsrf::InvalidToken do
      post "/admin/accounts/delete?account_id=#{alice_account.id}"
    end

    assert_raises Roda::RodaPlugins::RouteCsrf::InvalidToken do
      post "/admin/accounts/verify?account_id=#{alice_account.id}"
    end

    assert_raises Roda::RodaPlugins::RouteCsrf::InvalidToken do
      post "/admin/accounts/close?account_id=#{alice_account.id}"
    end

    assert_raises Roda::RodaPlugins::RouteCsrf::InvalidToken do
      post "/admin/accounts/open?account_id=#{alice_account.id}"
    end
  end

  def test_admin_without_two_fa_cannot_access_admin_page
    account = create_and_verify_account!(user_name: "test admin", email: "admin@example.com")
    Admin.new(account_id: account.id).save

    visit "/admin"

    assert_current_path "/otp-setup"
    refute_content "Admin - test admin"
    user_names = DB[:accounts].exclude(user_name: "test admin").select_map(:user_name)
    user_names.each { |user_name| refute_content user_name }
  end

  def test_admin_with_2_fa_enabled_can_access_admin_page
    setup_admin

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

    assert_content "alice@example.com"
    assert_content "test.unverified@example.com"
    assert_content "test.verified@example.com"
    assert_content "test.closed@example.com"
    assert_content "test unverified accou..." # Test the truncate view helpers method
    assert_content "test verified account"
    assert_content "test closed account"

    click_on "Verified"
    assert_content "alice@example.com"
    assert_content "test.verified@example.com"
    assert_content "test verified account"
    refute_content "test.unverified@example.com"
    refute_content "test.closed@example.com"
    refute_content "test unverified accou..."
    refute_content "test closed account"

    click_on "Unverified"
    refute_content "alice@example.com"
    assert_content "test.unverified@example.com"
    refute_content "test.verified@example.com"
    refute_content "test.closed@example.com"
    assert_content "test unverified accou..."
    refute_content "test verified account"
    refute_content "test closed account"

    click_on "Closed"
    refute_content "alice@example.com"
    refute_content "test.unverified@example.com"
    refute_content "test.verified@example.com"
    assert_content "test.closed@example.com"
    refute_content "test unverified accou..."
    refute_content "test verified account"
    assert_content "test closed account"

    click_on "OTP ON"
    assert_content "alice@example.com"
    refute_content "test.unverified@example.com"
    refute_content "test.verified@example.com"
    refute_content "test.closed@example.com"
    refute_content "test unverified accou..."
    refute_content "test verified account"
    refute_content "test closed account"

    click_on "OTP OFF"
    refute_content "alice@example.com"
    assert_content "test.unverified@example.com"
    assert_content "test.verified@example.com"
    assert_content "test.closed@example.com"
    assert_content "test unverified accou..."
    assert_content "test verified account"
    assert_content "test closed account"

    click_on "ADMIN"
    assert_content "alice@example.com"
    refute_content "test.unverified@example.com"
    refute_content "test.verified@example.com"
    refute_content "test.closed@example.com"
    refute_content "test unverified accou..."
    refute_content "test verified account"
    refute_content "test closed account"
  end

  def test_cannot_access_show_page_of_an_admin_account
    alice_account = setup_admin

    visit "/admin/accounts"

    refute_link "Alice", href: "/admin/accounts/#{alice_account.id}"

    visit "/admin/accounts/#{alice_account.id}"

    assert_current_path "/admin/accounts"
    assert_css ".alert-danger"
    assert_content "Cannot perform this action on admin user"
  end

  def test_admin_cannot_perform_post_actions_on_admin_accounts
    alice_account = setup_admin
    actions = %w[open close verify delete]
    actions.each do |action|
      assert_raises Roda::RodaPlugins::RouteCsrf::InvalidToken do
        post "/admin/accounts/#{alice_account.id}/#{action}"
      end
    end
  end

  def test_admin_can_delete_a_non_admin_account_with_checkbox_checked
    soon_deleted_account = create_and_verify_account!(user_name: "soon deleted", email: "soondeleted@example.com")
    batch_id = soon_deleted_account.active_batch_id
    entry = Entry.new(weight: "60.0", day: "2021-06-01", note: "",
      account_id: soon_deleted_account.id, batch_id: batch_id).save

    logout!
    setup_admin

    visit "/admin/accounts"

    click_link "soon deleted", href: "/admin/accounts/#{soon_deleted_account.id}"

    assert_current_path "/admin/accounts/#{soon_deleted_account.id}"
    assert_content "Admin Panel"
    assert_content "Admin - Alice"

    assert_content "Account Summary"
    assert_content "soon deleted"
    assert_content "soondeleted@example.com"
    assert_content "1 Batch" # The default one
    assert_content "1 Entry"
    assert_content "Last entry: 01 Jun 2021"
    check "confirm-delete-account"

    click_on "Confirm Deletion"

    assert_current_path "/admin/accounts"
    assert_css ".alert-success"
    assert_content "Account successfully deleted"
    refute_content "soon deleted"
    refute_content "soondeleted@example.com"
    refute_link "soon deleted", href: "/admin/accounts/#{soon_deleted_account.id}"

    assert_nil Account[soon_deleted_account.id]
    assert_nil Batch[batch_id]
    assert_nil Entry[entry.id]
  end

  def test_admin_cannot_delete_a_non_admin_account_without_checking_confirmation_checkbox
    not_soon_deleted_account = create_and_verify_account!(user_name: "not soon deleted", email: "notsoondeleted@example.com")
    batch_id = not_soon_deleted_account.active_batch_id
    entry = Entry.new(weight: "60.0", day: "2021-06-01", note: "",
      account_id: not_soon_deleted_account.id, batch_id: batch_id).save

    logout!
    setup_admin

    visit "/admin/accounts"

    click_link "not soon deleted", href: "/admin/accounts/#{not_soon_deleted_account.id}"
    assert_current_path "/admin/accounts/#{not_soon_deleted_account.id}"

    click_on "Confirm Deletion"

    assert_current_path "/admin/accounts/#{not_soon_deleted_account.id}"
    assert_css ".alert-danger"
    assert_content "You did not checked the confirmation checkbox, action cancelled."
    assert_content "not soon deleted"
    assert_content "soondeleted@example.com"

    refute_nil Account[not_soon_deleted_account.id]
    refute_nil Batch[batch_id]
    refute_nil Entry[entry.id]

    visit "/admin/accounts"
    assert_link "not soon deleted", href: "/admin/accounts/#{not_soon_deleted_account.id}"
  end

  def test_admin_can_verify_a_non_admin_account
    unverified_account = create_account!(user_name: "unverified", email: "unverified@example.com")
    logout!

    setup_admin

    visit "/admin"
    click_link "unverified", href: "/admin/accounts/#{unverified_account.id}"

    assert_equal 200, status_code
    assert_current_path "/admin/accounts/#{unverified_account.id}"

    assert_content "Admin Panel"
    assert_content "Admin - Alice"
    assert_content "Account Summary"
    assert_content "unverified"
    assert_content "unverified@example.com"
    assert_content "1 Batch"
    assert_content "0 Entries"
    assert_content "Last entry: /"

    click_on "Verify"
    assert_equal 200, status_code
    assert_current_path "/admin/accounts/#{unverified_account.id}"
    assert_css ".alert-success"
    assert_content "Account successfully verified"
    assert_content "unverified"
    assert_content "Account Summary"
    assert_content "unverified@example.com"

    assert unverified_account.reload.is_verified?
    assert_nil DB[:account_verification_keys].where(id: unverified_account.id).first

    refute_button "Verify"
  end

  def test_admin_can_close_a_non_admin_account
    active_account = create_account!(user_name: "active", email: "active@example.com")
    logout!

    setup_admin

    visit "/admin"
    click_link "active", href: "/admin/accounts/#{active_account.id}"
    assert_current_path "/admin/accounts/#{active_account.id}"
    assert_content "Admin Panel"
    assert_content "Admin - Alice"
    assert_content "Account Summary"
    assert_content "active"
    assert_content "active@example.com"
    assert_content "1 Batch"
    assert_content "0 Entries"
    assert_content "Last entry: /"

    click_on "Close"
    assert_current_path "/admin/accounts/#{active_account.id}"
    assert_css ".alert-success"
    assert_content "Account successfully closed"
    assert_content "active"
    assert_content "active@example.com"
    refute_button "Close"
    assert_button "Open"

    assert active_account.reload.is_closed?
  end

  def test_admin_can_open_a_closed_non_admin_account
    soon_reopened_account = create_and_verify_account!(user_name: "soon reopened", email: "soonreopened@example.com")
    logout!
    soon_reopened_account.update(status_id: 3)

    setup_admin

    visit "/admin"
    click_link "soon reopened", href: "/admin/accounts/#{soon_reopened_account.id}"
    assert_current_path "/admin/accounts/#{soon_reopened_account.id}"
    assert_content "Admin Panel"
    assert_content "Admin - Alice"
    assert_content "Account Summary"
    assert_content "soon reopened"
    assert_content "soonreopened@example.com"
    assert_content "1 Batch"
    assert_content "0 Entries"
    assert_content "Last entry: /"

    click_on "Open"
    assert_current_path "/admin/accounts/#{soon_reopened_account.id}"
    assert_css ".alert-success"
    assert_content "Account successfully opened and set to verified status"
    assert_content "soon reopened"
    assert_content "soonreopened@example.com"
    refute_button "Open"
    assert_button "Close"
    refute soon_reopened_account.reload.is_closed?
  end
end
