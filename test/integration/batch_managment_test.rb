require_relative "../test_helpers"

class BatchManegmentTest < CapybaraTestCase
  def load_fixtures
    @alice_account = create_and_verify_account!
    login! # needed to create default batch and mensuration
    logout!

    # Ensure the account id is correct
    assert_equal 1, @alice_account.id

    # After login, which redirects to /entries/new, a new active batch is automatically
    # created, with name "New Batch". Here we insert a second one
    Batch.new(account_id: 1, active: false, name: "past batch", target: "50.0").save

    # Cannot use insert here beacuse of the column encryption
    Entry.new(day: "2020-11-01", weight: "51.0", note: "", account_id: 1, batch_id: 1).save
    Entry.new(day: "2020-11-02", weight: "54.0", note: "", account_id: 1, batch_id: 1).save
    Entry.new(day: "2020-12-01", weight: "51.0", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2020-12-02", weight: "52.0", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2020-12-03", weight: "53.0", note: "", account_id: 1, batch_id: 2).save
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
      login!
      super
    end
  end

  def test_can_view_index_of_batches
    visit "/entries"
    assert_link "New Batch", href: "/batches"
    click_on "New Batch"

    assert_current_path "/batches"
    assert_content "Batches"
    assert_button "New Batch"

    assert_css ".alert-info"
    assert_content "NAME"
    assert_content "TARGET"
    assert_content "FIRST"
    assert_content "LAST"
    assert_content "ACTIVE"
    assert_content "ENTRIES"

    assert_content "New Batch"
    assert_content "past batch"
    assert_content "50.0"
    assert_content "0.0"
  end

  def test_link_to_batch_related_entries_on_batches_index_page
    visit "/batches"

    assert_link href: "/entries"
  end

  def test_link_to_batch_related_entries_in_batch_edit_page
    batch = Batch.where(name: "New Batch", account_id: 1, active: true).first
    visit "/batches"
    assert_current_path "/batches"
    assert_link "New Batch", href: "/batches/#{batch.id}/edit"
    click_link "New Batch", href: "/batches/#{batch.id}/edit"
    assert_link "View Entries", href: "/entries?batch_id=#{batch.id}"
    click_link "View Entries"
    assert_current_path "/entries?batch_id=#{batch.id}"
  end

  def test_can_add_new_batch_with_valid_inputs
    visit "/batches"
    click_button "New Batch"

    fill_in "Batch Name", with: "test batch"
    fill_in "Target Weight", with: "50.0"
    click_on "Create"

    assert_current_path "/batches"
    assert_content "Batch successfully created"
    assert_css ".alert-success"
    assert_content "test batch"
  end

  def test_cannot_add_new_batch_with_invalid_name
    original_number_of_batches = Batch.count

    visit "/batches"
    click_button "New Batch"

    fill_in "Batch Name", with: "Too Long" * 20
    fill_in "Target Weight", with: "50.0"
    click_on "Create"

    assert_current_path "/batches"
    assert_content "name must have 30 characters max"
    assert_css ".alert-danger"
    refute_content "Too Long"
    assert_equal original_number_of_batches, Batch.count
  end

  def test_cannot_add_new_batch_with_invalid_target
    original_number_of_batches = Batch.count

    visit "/batches"
    click_button "New Batch"

    fill_in "Batch Name", with: "Test Batch"
    fill_in "Target Weight", with: "50000.0"
    click_on "Create"

    assert_current_path "/batches"
    assert_content "Invalid target weight, must be between 20.0 and 999.9"
    assert_css ".alert-danger"
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

    click_on "Update Batch"

    assert_current_path "/batches"
    assert_content "Old Batch"
    refute_content "past batch"
  end

  # Wierd behavior - OK in tests and development BUT bug in production on the entries index page only
  # #<Encoding::CompatibilityError: incompatible character encodings: UTF-8 and ASCII-8BIT>
  def test_can_update_a_batch_name_with_utf_8_characters
    visit "/batches"

    click_link "New Batch"
    batch = Batch.where(name: "New Batch", account_id: 1, active: true).first

    assert_current_path "/batches/#{batch.id}/edit"

    fill_in "Name", with: "vacances été"
    fill_in "Target Weight", with: "70.0"

    click_on "Update Batch"

    assert_current_path "/batches"
    assert_content "vacances été"
    refute_link "New Batch"

    click_on "Entries"

    assert_current_path "/entries"
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

    click_on "Update Batch"

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

    click_on "Update Batch"

    assert_current_path "/batches/#{batch.id}"
    assert_css ".alert-danger"
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

    click_on "Update Batch"

    assert_current_path "/batches/#{batch.id}"
    assert_css ".alert-danger"
    assert_content "name must have 30 characters max"
    refute_content "Too Long"
  end

  def test_can_make_a_batch_active
    visit "/batches"

    click_on "past batch"
    past_batch = Batch.where(name: "past batch", account_id: 1, active: false).first

    assert_current_path "/batches/#{past_batch.id}/edit"

    check "Make active"

    click_on "Update Batch"

    assert_current_path "/batches"

    refute_nil Batch.where(name: "past batch", account_id: 1, active: true).first
    assert_nil Batch.where(name: "New Batch", account_id: 1, active: true).first

    assert_equal 1, Batch.where(account_id: 1, active: true).count
  end

  def test_can_delete_a_batch_with_check_box_checked
    batch = Batch.where(name: "New Batch", account_id: 1, active: true).first
    refute_nil batch
    assert_equal 2, batch.entries.size

    visit "/batches"

    click_link "New Batch", href: "/batches/#{batch.id}/edit"
    assert_current_path "/batches/#{batch.id}/edit"

    click_on "Delete"
    check id: "confirm-delete-batch-checkbox"
    click_on "Confirm Deletion"

    assert_current_path "/batches"
    assert_css ".alert-success"
    assert_content "Batch has been successfully deleted"

    refute_link "New Batch"
    assert_nil Batch.where(name: "New Batch", account_id: 1).first
    assert_equal 0, Entry.where(batch_id: batch.id).count
  end

  def test_cannot_delete_a_batch_if_check_box_is_not_checked
    batch = Batch.where(name: "New Batch", account_id: 1, active: true).first
    refute_nil batch
    assert_equal 2, batch.entries.size

    visit "/batches"

    click_link "New Batch", href: "/batches/#{batch.id}/edit"

    assert_current_path "/batches/#{batch.id}/edit"

    click_on "Confirm Deletion"

    assert_current_path "/batches/#{batch.id}/edit"
    assert_css ".alert-danger"
    assert_content "Please tick the checkbox to confirm batch deletion"

    refute_nil Batch.where(name: "New Batch", account_id: 1).first
    assert_equal 2, Entry.where(batch_id: batch.id).count
  end
end
