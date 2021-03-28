require_relative "../test_helpers"

class EntriesActionTest < CapybaraTestCase
  def test_when_logged_in_and_getting_root_path_user_is_redirected_to_new_entry_page
    login!
    visit "/"
    assert_current_path "/entries/new"
  end

  class test_entries_index
    login!
    visit "/entries"
    
  end
end