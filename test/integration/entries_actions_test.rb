require_relative "../test_helpers"

class EntriesActionTest < CapybaraTestCase
  def before_all
    super
    clean_test_db!
    @alice_account = create_and_verify_account!
    @alice_account.mensuration.update(height: "160")
  end

  def after_all
    clean_test_db!
    super
  end

  def delete_batches(account_id)
    Batch.each(&:destroy)
    assert_equal 0, Batch.all.size
  end

  def around
    # Make sure there is no preexisting batch
    delete_batches(@alice_account.id)

    DB.transaction(rollback: :always) do
      login!
      super
    end
  end

  def test_can_create_entry_without_an_already_existing_batch
    # artificially delete any preexisting batch for testing purpose
    delete_batches(@alice_account.id)

    visit "/entries/new"
    assert_current_path "/entries/new"
    assert_content "New Entry"
    assert_content "Day"
    assert_content "Weight"
    assert_content "Note"
    assert_button "Validate"

    fill_in "Day", with: "30/04/2021"
    fill_in "Weight", with: "52.0"
    fill_in "Note", with: "This is my first test entry"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Fri 30 Apr 2021"
    assert_content "52.0"
    assert_content "20.3" # BMI
    # assert_content "This is my first test entry" Cannot test it without JS testing driver enabled
    assert_equal 1, Batch.where(account_id: @alice_account.id).all.length

    # Add another entry to test delta

    visit "/entries/new"

    fill_in "Day", with: "01/05/2021"
    fill_in "Weight", with: "53.0"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Fri 30 Apr 2021"
    assert_content "Sat 01 May 2021"
    assert_content "52.0"
    assert_content "53.0"
    assert_content "+1.0"
    assert_content "20.3" # First BMI
    assert_content "20.7" # Second BMI
    assert_equal 1, Batch.where(account_id: @alice_account.id).all.length
  end

  def test_can_create_entry_with_an_already_existing_active_batch
    # Beacuse of login! action called in the around hook, an active batch has already been created
    batches = Batch.where(account_id: @alice_account.id).all
    assert_equal 1, batches.size
    active_batch = batches.first

    visit "/entries/new"
    assert_current_path "/entries/new"
    assert_content "New Entry"
    assert_content "Day"
    assert_content "Weight"
    assert_content "Note"
    assert_button "Validate"

    fill_in "Day", with: "30/04/2021"
    fill_in "Weight", with: "52.0"
    fill_in "Note", with: "This is my first test entry"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Fri 30 Apr 2021"
    assert_content "52.0"
    # assert_content "This is my first test entry" Cannot test it without JS testing driver enabled

    entry = Entry.where(day: "2021-04-30", account_id: @alice_account.id).first
    assert_equal active_batch.id, entry.batch.id

    # Add another entry to test delta

    visit "/entries/new"

    fill_in "Day", with: "01/05/2021"
    fill_in "Weight", with: "53.0"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Fri 30 Apr 2021"
    assert_content "Sat 01 May 2021"
    assert_content "52.0"
    assert_content "53.0"
    assert_content "+1.0"

    entry = Entry.where(day: "2021-05-01", account_id: @alice_account.id).first
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

    fill_in "Day", with: "30/04/2021"
    fill_in "Weight", with: "52.0"
    fill_in "Note", with: "This is my first test entry"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Fri 30 Apr 2021"
    assert_content "52.0"
    # assert_content "This is my first test entry" Cannot test it without JS testing driver enabled

    entry = Entry.where(day: "2021-04-30", account_id: @alice_account.id).first
    assert_equal active_batch, entry.batch

    # Add another entry to test delta

    visit "/entries/new"

    fill_in "Day", with: "01/05/2021"
    fill_in "Weight", with: "53.0"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Fri 30 Apr 2021"
    assert_content "Sat 01 May 2021"
    assert_content "52.0"
    assert_content "53.0"
    assert_content "+1.0"

    entry = Entry.where(day: "2021-05-01", account_id: @alice_account.id).first
    assert_equal active_batch.id, entry.batch.id

    assert_equal 0, inactive_batch.reload.entries.length
  end

  def test_gets_redirected_to_batches_pages_if_many_batches_but_none_active
    assert_equal 1, Batch.where(account_id: @alice_account.id).all.size
    Batch.where(account_id: @alice_account.id).first.update(active: false)

    Batch.new(account_id: @alice_account.id, active: false, name: "Inactive Batch").save

    visit "/entries"

    assert_current_path "/batches"
    assert_css ".alert-danger"
    assert_content "No Active batch found, please create or one or make one active"
  end

  def test_link_to_batches_page_on_entries_index_page
    visit "/entries"
    assert_link href: "/batches"
    assert_content "Target: 0.0"
  end

  def test_can_update_an_entry
    visit "/entries/new"

    fill_in "Day", with: "30/04/2021"
    fill_in "Weight", with: "52.0"
    click_on "Validate"

    active_batch = Batch.where(account_id: @alice_account.id).first

    click_on "Fri 30 Apr 2021"

    assert_content "Edit Entry"
    assert_field "Day", with: "2021-04-30"
    assert_field "Weight", with: "52.0"
    assert_field "Note", with: ""
    assert_button "Validate"
    assert_button "Delete"

    fill_in "Day", with: "01/05/2021"
    fill_in "Weight", with: "53.0"
    click_on "Validate"

    assert_current_path "/entries"
    assert_content "Sat 01 May 2021"
    assert_content "53.0"

    assert_equal 1, Batch.where(account_id: @alice_account.id).all.length
    assert_equal 1, Entry.where(account_id: @alice_account.id).all.length
    assert_equal active_batch, Entry.where(account_id: @alice_account.id).first.batch
  end

  def test_can_delete_an_entry
    visit "/entries/new"

    fill_in "Day", with: "30/04/2021"
    fill_in "Weight", with: "52.0"
    click_on "Validate"

    active_batch = Batch.where(account_id: @alice_account.id).first

    click_on "Fri 30 Apr 2021"

    click_on "Delete"

    assert_current_path "/entries"
    refute_content "Fri 30 Apr 2021"
    refute_content "52.0"

    assert_equal 0, active_batch.entries.length
  end

  def test_performs_validation_on_weight_before_encryption
    visit "/entries/new"

    fill_in "Day", with: "30/04/2021"
    fill_in "Weight", with: "5552.0"

    click_on "Validate"

    assert_current_path "/entries"
    assert_css ".alert-danger"
    assert_content "Invalid weight, must be between 20.0 and 999.9"
    assert_field "Day", with: "2021-04-30"
    assert_field "Weight", with: "5552.0"
    assert_field "Note", with: ""
  end
end
