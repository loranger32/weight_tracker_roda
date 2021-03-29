require_relative "../test_helpers"

class EntriesActionTest < CapybaraTestCase

  def test_entries_index
    login!
    visit "/entries"
  end
end
