require_relative "../test_helpers"

class EntriesActionTest < CapybaraTestCase
  def before_all
    super
    clean_test_db!
    @alice_account = create_and_verify_account!
    login! # Creates a default batch and mensuration for account
    @alice_account.mensuration.update(height: "160")
    logout!
  end

  def after_all
    clean_test_db!
    super
  end

  def delete_batches
    Batch.each(&:destroy)
    assert_equal 0, Batch.count
    assert_equal 0, Entry.count
  end

  def around
    # Make sure there is no preexisting batch
    delete_batches

    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      login!
      super
    end
  end

  def test_can_create_entry_without_an_already_existing_batch
    # artificially delete any preexisting batch for testing purpose
    delete_batches

    visit "/entries/new" # This should create a batch named New Batch for account
    assert_equal 1, Batch.count
    assert_equal 1, Batch.where(account_id: @alice_account.id).count
    assert_current_path "/entries/new"
    assert_content "New Entry"
    assert_content "Day"
    assert_content "Weight"
    assert_content "Alcohol"
    assert_content "Sport"
    assert_content "Note"
    assert_button "Validate"

    fill_in "Day", with: "01/01/2021"
    fill_in "Weight", with: "52.0"
    fill_in "Note", with: "This is my first test entry"
    select("No Alcohol")
    select("No Sport")
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Fri 01 Jan 2021"
    assert_content "52.0"
    assert_content "20.3" # BMI
    assert_content "🟢", count: 1
    refute_content "🟠"
    assert_content "🔴", count: 1
    refute_content "⚪"
    # assert_content "This is my first test entry" Cannot test it without JS testing driver enabled
    assert_equal 1, Batch.where(account_id: @alice_account.id).count

    # Add another entry to test delta, alcohol and sport

    visit "/entries/new"

    fill_in "Day", with: "02/01/2021"
    fill_in "Weight", with: "53.0"
    select("Some Alcohol")
    select("Some Sport")
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Fri 01 Jan 2021"
    assert_content "Sat 02 Jan 2021"
    assert_content "52.0"
    assert_content "53.0"
    assert_content "+1.0"
    assert_content "🟢", count: 1
    assert_content "🟠", count: 2
    assert_content "🔴", count: 1
    refute_content "⚪"
    assert_content "20.3" # First BMI
    assert_content "20.7" # Second BMI
    assert_equal 1, Batch.where(account_id: @alice_account.id).count

    # Add a third entry to test alcohol and sport

    visit "/entries/new"

    fill_in "Day", with: "03/01/2021"
    fill_in "Weight", with: "53.0"
    select("Much Alcohol")
    select("Much Sport")
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "🟢", count: 2
    assert_content "🟠", count: 2
    assert_content "🔴", count: 2
    refute_content "⚪"

    # Simulate an entry without alcohol consumption info

    alice_batch_id = Batch.where(account_id: @alice_account.id).first.id
    Entry.new(day: Date.parse("2021-01-04"), weight: "50.0", note: "A good note",
      alcohol_consumption: "", sport: "", account_id: 1, batch_id: alice_batch_id).save

    visit "/entries"
    assert_content "🟢", count: 2
    assert_content "🟠", count: 2
    assert_content "🔴", count: 2
    assert_content "⚪", count: 2
  end

  def test_can_create_entry_with_an_already_existing_active_batch
    # Beacuse of login! action called in the around hook, an active batch has already been created
    assert_equal 1, Batch.count

    assert_equal 1, Batch.where(account_id: @alice_account.id).count
    active_batch = Batch.first

    visit "/entries/new"
    assert_current_path "/entries/new"
    assert_content "New Entry"
    assert_content "Day"
    assert_content "Weight"
    assert_content "Note"
    assert_button "Validate"

    fill_in "Day", with: "03/01/2021"
    fill_in "Weight", with: "52.0"
    fill_in "Note", with: "This is my first test entry"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Sun 03 Jan 2021"
    assert_content "52.0"
    # assert_content "This is my first test entry" Cannot test it without JS testing driver enabled

    entry = Entry.where(day: "2021-01-03", account_id: @alice_account.id).first
    assert_equal active_batch.id, entry.batch.id

    # Add another entry to test delta

    visit "/entries/new"

    fill_in "Day", with: "04/01/2021"
    fill_in "Weight", with: "53.0"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Sun 03 Jan 2021"
    assert_content "Mon 04 Jan 2021"
    assert_content "52.0"
    assert_content "53.0"
    assert_content "+1.0"

    entry = Entry.where(day: "2021-01-04", account_id: @alice_account.id).first
    assert_equal active_batch.id, entry.batch.id
  end

  def test_can_create_an_entry_with_many_batches_and_one_active
    inactive_batch = Batch.new(account_id: @alice_account.id, active: false, name: "Inactive Batch").save
    batches = Batch.where(account_id: @alice_account.id).all
    assert_equal 2, batches.size
    active_batch = Batch.where(account_id: @alice_account.id, active: true).first

    visit "/entries/new"
    assert_current_path "/entries/new"
    assert_content "New Entry"
    assert_content "Day"
    assert_content "Weight"
    assert_content "Note"
    assert_button "Validate"

    fill_in "Day", with: "05/01/2021"
    fill_in "Weight", with: "52.0"
    fill_in "Note", with: "This is my first test entry"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Tue 05 Jan 2021"
    assert_content "52.0"
    # assert_content "This is my first test entry" Cannot test it without JS testing driver enabled

    entry = Entry.where(day: "2021-01-05", account_id: @alice_account.id).first
    assert_equal active_batch, entry.batch

    # Add another entry to test delta

    visit "/entries/new"

    fill_in "Day", with: "06/01/2021"
    fill_in "Weight", with: "53.0"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Tue 05 Jan 2021"
    assert_content "Wed 06 Jan 2021"
    assert_content "52.0"
    assert_content "53.0"
    assert_content "+1.0"

    entry = Entry.where(day: "2021-01-06", account_id: @alice_account.id).first
    assert_equal active_batch.id, entry.batch.id

    assert_equal 0, inactive_batch.reload.entries.length
  end

  def test_cannot_create_entry_with_invalid_params
    # Insert a valid entry first
    visit "/entries/new"
    fill_in "Day", with: "07/01/2021"
    fill_in "Weight", with: "53.0"
    fill_in "note", with: "Valid note"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Thu 07 Jan 2021"

    assert_equal 1, Entry.where(account_id: @alice_account.id).count

    # Invalid Date format
    visit "/entries/new"
    fill_in "Day", with: "Not A Date"
    fill_in "Weight", with: "53.0"
    fill_in "note", with: "Valid note"

    # Issue with invalid date format will be catch by the Roda typecast_param plugin
    assert_raises(Roda::RodaPlugins::TypecastParams::Error) { click_on "Validate" }
    assert_equal 1, Entry.where(account_id: @alice_account.id).count

    # Try to create an entry with same date
    visit "/entries/new"
    fill_in "Day", with: "07/01/2021"
    fill_in "Weight", with: "53.0"
    fill_in "note", with: "Valid note"
    click_on "Validate"

    assert_current_path "/entries" # Default path after posting to /entries
    assert_css ".alert-danger"
    assert_content "Can't have two entries for the same day"
    assert_equal 1, Entry.where(account_id: @alice_account.id).count

    # Try to create entry with invalid weight
    visit "/entries/new"
    fill_in "Day", with: "08/01/2021"
    fill_in "Weight", with: "5553.0"
    fill_in "note", with: "Valid note"
    click_on "Validate"

    assert_current_path "/entries"
    assert_css ".alert-danger"
    assert_content "Invalid weight, must be between 0.0 and 999.9"
    assert_equal 1, Entry.where(account_id: @alice_account.id).count

    # Try to create entry with too long note
    visit "/entries/new"
    fill_in "Day", with: "08/01/2021"
    fill_in "Weight", with: "53.0"
    fill_in "note", with: ("Valid note" * 600)
    click_on "Validate"

    assert_current_path "/entries"
    assert_css ".alert-danger"
    assert_content "note is longer than 600 characters"
    assert_equal 1, Entry.where(account_id: @alice_account.id).count
  end

  def test_can_create_an_entry_and_attach_it_to_a_non_active_batch
    assert_equal 1, Batch.where(account_id: @alice_account.id).count
    @alice_account.add_batch(name: "non active batch", active: false)
    assert_equal 2, Batch.where(account_id: @alice_account.id).count

    visit "/entries/new"

    fill_in "Day", with: "08/01/2021"
    fill_in "Weight", with: "53.0"
    fill_in "note", with: "Valid note"
    select("non active batch")
    click_on "Validate"

    assert_current_path "/entries"
    assert_css ".alert-success"
    assert_equal 1, Entry.where(account_id: @alice_account.id).count
    assert_equal 1, Batch.where(name: "non active batch").first.entries.count
    assert_equal 0, Batch.where(name: "New Batch").first.entries.count
  end

  def test_gets_redirected_to_batches_pages_if_many_batches_but_none_active
    assert_equal 1, Batch.where(account_id: @alice_account.id).count
    Batch.where(account_id: @alice_account.id).first.update(active: false)

    Batch.new(account_id: @alice_account.id, active: false, name: "Inactive Batch").save

    visit "/entries"

    assert_current_path "/batches"
    assert_css ".alert-danger"
    assert_content "No Active batch found, please create or one or make one active"
  end

  def test_link_to_batches_page_on_entries_index_page
    visit "/entries"
    assert_link "Switch Batch", href: "/batches"
    assert_content "0.0 Kg"
  end

  def test_back_to_entries_button_on_new_entry_form_redirects_to_entries_of_active_batch
    visit "/entries/new"
    assert_link href: "/entries"
  end

  def test_back_to_entries_button_on_update_entry_from_active_batch_redirects_to_entries_of_active_batch
    # Create an entry in the currently active batch
    visit "/entries/new"
    fill_in "Day", with: "09/01/2021" # It's a saturday
    fill_in "Weight", with: "53.0"
    fill_in "note", with: "Valid note 1"
    click_on "Validate"

    # Create a second batch, which will be active by default
    visit "/batches"
    fill_in "Batch Name", with: "Test Batch"
    fill_in "Target Weight", with: "80,0"
    click_on "Create"

    # Create two new entries on new batch
    visit "/entries/new"
    fill_in "Day", with: "10/01/2021"
    fill_in "Weight", with: "53.5"
    fill_in "note", with: "Valid note 2"
    click_on "Validate"

    visit "/entries/new"
    fill_in "Day", with: "11/01/2021"
    fill_in "Weight", with: "54.0"
    fill_in "note", with: "Valid note 3"
    click_on "Validate"

    assert_current_path "/entries"
    click_on "All Entries"
    assert_current_path "/entries?all_batches=true"
    click_on "Sat 09 Jan 2021"    # Entry from first batch
    entry = Entry.where(day: "2021-01-09").first
    assert_current_path "/entries/#{entry.id}/edit"
    assert_link "Back to entries", href: "/entries?batch_id=#{entry.batch_id}"
  end

  def test_can_update_an_entry_with_valid_params
    visit "/entries/new"

    fill_in "Day", with: "09/01/2021"
    fill_in "Weight", with: "52.0"
    select("No Alcohol")
    click_on "Validate"

    active_batch = Batch.where(account_id: @alice_account.id).first

    click_on "Sat 09 Jan 2021"

    assert_content "Edit Entry"
    assert_field "Day", with: "2021-01-09"
    assert_field "Weight", with: "52.0"
    assert_field "Note", with: ""
    assert page.has_select?("alcohol_consumption", selected: "No Alcohol")
    refute page.has_select?("alcohol_consumption", selected: "Some Alcohol")
    assert_button "Validate"
    assert_button "Delete"

    fill_in "Day", with: "10/01/2021"
    fill_in "Weight", with: "54.0"
    fill_in "Note", with: "Updated entry"
    select("Some Alcohol")
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Sun 10 Jan 2021"
    assert_content "54.0"
    assert_content "🟠"
    refute_content "🟢"

    assert_equal "Updated entry", Entry.where(account_id: @alice_account.id).first.note
    assert_equal 1, Batch.where(account_id: @alice_account.id).count
    assert_equal 1, Entry.where(account_id: @alice_account.id).count
    assert_equal active_batch, Entry.where(account_id: @alice_account.id).first.batch

    # Transfer entry to another batch
    @alice_account.add_batch(name: "test batch", active: false)

    click_on "Sun 10 Jan 2021"
    assert_content "Edit Entry"
    select "test batch"
    click_on "Validate"

    assert_equal 2, Batch.where(account_id: @alice_account.id).count
    assert_equal 1, Entry.where(account_id: @alice_account.id).count
    assert_equal 0, Batch.where(name: "New Batch").first.entries.size
    assert_equal 1, Batch.where(name: "test batch").first.entries.size
    assert_current_path "/entries"
    refute_content "Sun 10 Jan 2021"

    visit "/batches"
    click_on "test batch"
    test_batch = Batch.where(name: "test batch").first
    assert_current_path "/batches/#{test_batch.id}/edit"
    click_on "View #{test_batch.entries.count} Entries"
    assert_content "Sun 10 Jan 2021"
  end

  def test_cannot_update_an_entry_with_invalid_params
    # Insert a valid entry first
    visit "/entries/new"
    fill_in "Day", with: "11/01/2021"
    fill_in "Weight", with: "53.0"
    fill_in "note", with: "Valid first note"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Mon 11 Jan 2021"

    # Insert a second entry to test entry per day uniqueness
    visit "/entries/new"
    fill_in "Day", with: "12/01/2021"
    fill_in "Weight", with: "54.0"
    fill_in "note", with: "Valid second note"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Tue 12 Jan 2021"

    assert_equal 2, Entry.where(account_id: @alice_account.id).count

    @alice_account.reload
    first_test_entry = @alice_account.entries.select { _1.weight == "53.0"}.first
    second_test_entry = @alice_account.entries.select { _1.weight == "54.0"}.first

    # Invalid Date format
    click_on "Mon 11 Jan 2021"
    assert_current_path "/entries/#{first_test_entry.id}/edit"

    fill_in "Day", with: "Not A Date"
    fill_in "Weight", with: "53.0"
    fill_in "note", with: "Valid note"

    # Issue with invalid date format will be catch by the Roda typecast_param plugin
    assert_raises(Roda::RodaPlugins::TypecastParams::Error) { click_on "Validate" }

    # Try to update an entry with same date as another entry
    visit "/entries"
    click_on "Mon 11 Jan 2021"
    assert_current_path "/entries/#{first_test_entry.id}/edit"
    fill_in "Day", with: "12/01/2021"
    click_on "Validate"

    assert_current_path "/entries/#{first_test_entry.id}" # Default path after posting to /entries/id/edit
    assert_css ".alert-danger"
    assert_content "Can't have two entries for the same day"

    # Try to update entry with invalid weight
    visit "/entries"
    click_on "Mon 11 Jan 2021"
    fill_in "Weight", with: "5553.0"
    click_on "Validate"

    assert_current_path "/entries/#{first_test_entry.id}"
    assert_css ".alert-danger"
    assert_content "Invalid weight, must be between 0.0 and 999.9"

    # Try to update entry with too long note
    visit "/entries"
    click_on "Mon 11 Jan 2021"
    fill_in "note", with: ("Valid note" * 600)
    click_on "Validate"

    assert_current_path "/entries/#{first_test_entry.id}"
    assert_css ".alert-danger"
    assert_content "note is longer than 600 characters"
  end

  def test_can_delete_an_entry
    visit "/entries/new"

    fill_in "Day", with: "13/01/2021"
    fill_in "Weight", with: "52.0"
    click_on "Validate"

    active_batch = Batch.where(account_id: @alice_account.id).first

    click_on "Wed 13 Jan 2021"

    click_on "Delete"

    assert_current_path "/entries"
    refute_content "Wed 13 Jan 2021"
    refute_content "52.0"

    assert_equal 0, active_batch.entries.length
  end
end
