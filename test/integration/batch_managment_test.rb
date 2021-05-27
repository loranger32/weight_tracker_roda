require_relative "../test_helpers"

class BatchManegmentTest < CapybaraTestCase
  def load_fixtures
    clean_fixtures
    create_and_verify_account!

    # Ensure the account id is correct
    @account = Account.where(user_name: "Alice").first
    assert_equal 1, @account.id

    # After login, which redirects to /entries/new, a new active batch is automatically
    # created, with name "Batch 1". Here we insert a second one
    Batch.new(account_id: 1, active: false, name: "past batch", target: "50.0").save

    # Cannot use insert here beacuse of the column encryption
    Entry.new(day: "2020-11-01" , weight: "51.0", note: "", account_id: 1, batch_id: 1).save
    Entry.new(day: "2020-11-02" , weight: "54.0", note: "", account_id: 1, batch_id: 1).save
    Entry.new(day: "2020-12-01" , weight: "51.0", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2020-12-02" , weight: "52.0", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2020-12-03" , weight: "53.0", note: "", account_id: 1, batch_id: 2).save
  end

  def clean_fixtures
    [:batches, :entries, :account_active_session_keys,
      :account_authentication_audit_logs, :accounts].each do |table|
      DB[table].delete
      DB.reset_primary_key_sequence(table)
    end
  end

  def setup
    login!
  end

  def test_can_view_index_of_batches
    visit "/entries"
    assert_link "Batch 1", href: "/batches"
    click_on "Batch 1"

    assert_current_path "/batches"
    assert_content "Batches"
    assert_link "New", href: "#"
    refute_link "Cancel", href: "#"
    assert_css ".invisible"

    assert_content "Current batch"
    assert_content "NAME"
    assert_content "TARGET"
    assert_content "FIRST"
    assert_content "LAST"
    assert_content "ACTIVE"
    assert_content "ENTRIES"

    assert_content "Batch 1"
    assert_content "past batch"
    assert_content "50.0"
    assert_content "/"
  end

  def test_link_to_batch_related_entries_on_batches_index_page
    visit "/batches"

    assert_link href: "/entries"
  end

  def test_link_to_batch_related_entries_in_batch_edit_page
    visit "/batches"
    click_on "Batch 1"
    batch = Batch.where(name: "Batch 1", account_id: 1, active: true).first
    assert_current_path "/batches/#{batch.id}/edit"
    assert_link href: "/entries?batch_id=#{batch.id}"
  end

  def test_can_add_new_batch_with_valid_inputs
    visit "/batches"
    click_on "New"

    fill_in "Batch Name", with: "test batch"
    fill_in "Target Weight", with: "50.0"
    click_on "Create"

    assert_current_path "/batches"
    assert_content "Batch successfully created"
    assert_css ".flash-notice"
    assert_content "test batch"
  end

  def test_cannot_add_new_batch_with_invalid_name
    original_number_of_batches = Batch.count

    visit "/batches"
    click_on "New"

    fill_in "Batch Name", with: "Too Long" * 20
    fill_in "Target Weight", with: "50.0"
    click_on "Create"

    assert_current_path "/batches"
    assert_content "name must have 30 characters max"
    assert_css ".flash-error"
    refute_content "Too Long"
    assert_equal original_number_of_batches, Batch.count
  end

  def test_cannot_add_new_batch_with_invalid_target
    original_number_of_batches = Batch.count

    visit "/batches"
    click_on "New"

    fill_in "Batch Name", with: "Test Batch"
    fill_in "Target Weight", with: "50000.0"
    click_on "Create"

    assert_current_path "/batches"
    assert_content "Invalid target weight, must be between 20.0 and 999.9"
    assert_css ".flash-error"
    refute_content "Too Long"
    assert_equal original_number_of_batches, Batch.count
  end


  def test_can_update_a_batch_name
    visit "/batches"

    click_on "past batch"
    batch = Batch.where(name: "past batch", account_id: 1, active: false).first

    assert_current_path "/batches/#{batch.id}/edit"

    assert_content "Name"
    assert_content "First Entry"
    assert_content "Last Entry"

    fill_in "Name", with: "Old Batch"

    click_on "Validate"

    assert_current_path "/batches"
    assert_content "Old Batch"
    refute_content "past batch"
  end

  def test_can_update_a_batch_target_weight
    visit "/batches"

    click_on "past batch"
    batch = Batch.where(name: "past batch", account_id: 1, active: false).first

    assert_current_path "/batches/#{batch.id}/edit"

    assert_content "Name"
    assert_content "First Entry"
    assert_content "Last Entry"

    fill_in "Target Weight", with: "55.0"

    click_on "Validate"

    assert_current_path "/batches"
    assert_content "55.0"
    refute_content "50.0"
  end

  def test_cannot_update_batch_target_with_invalid_target_weight
    visit "/batches"

    click_on "past batch"
    batch = Batch.where(name: "past batch", account_id: 1, active: false).first

    assert_current_path "/batches/#{batch.id}/edit"

    assert_content "Name"
    assert_content "First Entry"
    assert_content "Last Entry"

    fill_in "Target Weight", with: "fifty-five"

    click_on "Validate"

    assert_current_path "/batches/#{batch.id}"
    assert_css ".flash-error"
    assert_content "Invalid target weight, must be between 20.0 and 999.9"
    refute_content "fifty-five"
  end

  def test_cannot_update_batch_target_with_invalid_name
    visit "/batches"

    click_on "past batch"
    batch = Batch.where(name: "past batch", account_id: 1, active: false).first

    assert_current_path "/batches/#{batch.id}/edit"

    assert_content "Name"
    assert_content "First Entry"
    assert_content "Last Entry"

    fill_in "Name", with: "Too Long" * 20

    click_on "Validate"

    assert_current_path "/batches/#{batch.id}"
    assert_css ".flash-error"
    assert_content "name must have 30 characters max"
    refute_content "Too Long"
  end

  def test_can_make_a_batch_active
    visit "/batches"

    click_on "past batch"
    past_batch = Batch.where(name: "past batch", account_id: 1, active: false).first

    assert_current_path "/batches/#{past_batch.id}/edit"

    check "Make active"

    click_on "Validate"

    assert_current_path "/batches"

    refute_nil Batch.where(name: "past batch", account_id: 1, active: true).first
    assert_nil Batch.where(name: "Batch 1", account_id: 1, active: true).first

    assert_equal 1, Batch.where(account_id: 1, active: true).count
  end

  def test_can_delete_a_batch_with_check_box_checked
    visit "/batches"

    click_on "Batch 1"
    batch = Batch.where(name: "Batch 1", account_id: 1, active: true).first
    refute_nil batch
    assert_equal 2, batch.entries.size

    assert_current_path "/batches/#{batch.id}/edit"

    click_on "Delete"
    check id: "confirm-delete-batch-checkbox"
    click_on "Confirm Deletion"

    assert_current_path "/batches"
    assert_css ".flash-notice"
    assert_content "Batch has been successfully deleted"
    
    refute_content "Batch 1"
    assert_nil Batch.where(name: "Batch 1", account_id: 1).first
    assert_equal 0, Entry.where(batch_id: batch.id).count
  end

  def test_cannot_delete_a_batch_if_check_box_is_not_checked
    visit "/batches"

    click_on "Batch 1"
    batch = Batch.where(name: "Batch 1", account_id: 1, active: true).first
    refute_nil batch
    assert_equal 2, batch.entries.size

    assert_current_path "/batches/#{batch.id}/edit"

    click_on "Confirm Deletion"

    assert_current_path "/batches/#{batch.id}/edit"
    assert_css ".flash-error"
    assert_content "Please tick the checkbox to confirm batch deletion"
    
    refute_nil Batch.where(name: "Batch 1", account_id: 1).first
    assert_equal 2, Entry.where(batch_id: batch.id).count
  end
end
