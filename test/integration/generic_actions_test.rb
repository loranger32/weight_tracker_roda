require_relative "../test_helpers"

class GenericActionsTest < CapybaraTestCase
  def test_when_logged_in_and_no_entry_for_current_day_is_redirected_to_new_entry_page
    create_and_verify_account!
    visit "/"
    assert_current_path "/entries/new"
  end

  def test_when_logged_in_and_already_an_entry_for_current_day_is_redirected_to_index_page
    create_and_verify_account!
    account = Account.where(user_name: "Alice").first
    account.add_entry(weight: "50.0", note: "", day: Time.now, batch_id: account.active_batch_id)

    visit "/"
    assert_current_path "/entries"
  end

  def test_when_logged_in_can_get_a_404_page_response
    create_and_verify_account!
    visit "/non-existant"
    assert_equal 404, status_code
    assert_current_path "/non-existant"
    assert_content "404 ERROR"
    assert_link "Home Page"
  end
end
