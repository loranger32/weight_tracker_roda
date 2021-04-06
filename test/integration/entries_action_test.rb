require_relative "../test_helpers"

class EntriesActionTest < CapybaraTestCase

  def test_entries_index
    create_and_verify_account!

    visit "/entries"
  end
end
