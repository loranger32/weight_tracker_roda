require_relative "../test_helpers"

class GenericActionsTest < CapybaraTestCase
  def before_all
    super
    clean_test_db!
    @alice_account = create_and_verify_account!
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      login!
      super
    end
  end

  def test_when_logged_in_and_no_entry_for_current_day_is_redirected_to_new_entry_page
    visit "/"
    assert_current_path "/entries/new"
  end

  def test_when_logged_in_and_already_an_entry_for_current_day_is_redirected_to_index_page
    @alice_account.add_entry(weight: "50.0", note: "", alcohol_consumption: "",
      sport: "none", day: Time.now, batch_id: @alice_account.active_batch_id)

    visit "/"
    assert_current_path "/entries"
  end

  def test_when_logged_in_can_get_a_404_page_response
    visit "/non-existant"
    assert_equal 404, status_code
    assert_current_path "/non-existant"
    assert_content "404 ERROR"
    assert_link "Home Page"
  end
end
