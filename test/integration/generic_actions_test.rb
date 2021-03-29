require_relative "../test_helpers"

class GenericActionsTest < CapybaraTestCase
  def test_when_logged_in_and_getting_root_path_user_is_redirected_to_new_entry_page
    login!
    visit "/"
    assert_current_path "/entries/new"
  end

  def test_when_logged_in_can_get_a_404_page_response
    login!
    visit "/non-existant"
    assert_equal 404, status_code
    assert_current_path "/non-existant"
    assert_content "404 ERROR"
    assert_link "Home Page"
  end
end
