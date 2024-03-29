require_relative "../test_helpers"

class EntryBasicTest < HookedTestClass
  def load_fixtures
    @valid_params = {day: Date.parse("2021-01-01"), weight: "50.0", note: "A good note",
                     alcohol_consumption: "none", sport: "none", account_id: 1, batch_id: 1}

    Account.new(user_name: "Alice", email: "alice@example.com",
      # password = 'foobar'
      password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva").save

    Batch.new(account_id: 1, active: true, name: "Batch 1").save
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
      super
    end
  end

  def test_has_db_columns_attributes
    entry = Entry.new
    assert_respond_to(entry, :day)
    assert_respond_to(entry, :weight)
    assert_respond_to(entry, :note)
    assert_respond_to(entry, :alcohol_consumption)
    assert_respond_to(entry, :sport)
    assert_respond_to(entry, :account_id)
    assert_respond_to(entry, :batch_id)
  end

  def test_has_delta_virtual_attribute
    assert_respond_to(Entry.new, :delta)
  end

  def test_has_a_delta_to_target_virtual_attribute
    assert_respond_to(Entry.new, :delta_to_target)
  end

  def test_has_a_bmi_virtual_attribute
    assert_respond_to(Entry.new, :bmi)
  end

  def test_has_an_account_association
    entry = Entry.new(@valid_params)

    assert_instance_of Account, entry.account
    assert_equal "Alice", entry.account.user_name
  end

  def test_has_a_batch_association
    entry = Entry.new(@valid_params)

    assert_instance_of Batch, entry.batch
    assert_equal true, entry.batch.active
  end

  def test_entry_is_valid_with_valid_params
    entry = Entry.new(@valid_params)
    assert entry.valid?
  end

  def test_day_must_be_present
    entry = Entry.new(@valid_params.except(:day))
    refute entry.valid?
    assert entry.errors.has_key?(:day)
  end

  def test_weight_must_be_present
    entry = Entry.new(@valid_params.except(:weight))
    refute entry.valid?
    assert entry.errors.has_key?(:weight)
  end

  def test_account_id_must_be_present
    entry = Entry.new(@valid_params.except(:account_id))
    refute entry.valid?
    assert entry.errors.has_key?(:account_id)
  end

  def test_batch_id_must_be_present
    entry = Entry.new(@valid_params.except(:batch_id))
    refute entry.valid?
    assert entry.errors.has_key?(:batch_id)
  end

  def test_note_must_be_present
    entry = Entry.new(@valid_params.except(:note))
    refute entry.valid?
    assert entry.errors.has_key?(:note)
  end

  def test_note_can_be_empty_string
    entry = Entry.new(@valid_params.merge(note: ""))
    assert entry.valid?
  end

  def test_alcohol_consumption_can_be_empty_string
    entry = Entry.new(@valid_params.merge(alcohol_consumption: ""))
    assert entry.valid?
  end

  def test_alcohol_consumption_cannot_be_nil
    entry_1 = Entry.new(@valid_params.merge(alcohol_consumption: nil))
    refute entry_1.valid?

    entry_2 = Entry.new(@valid_params.except(:alcohol_consumption))
    refute entry_2.valid?
  end

  def test_alcohol_consumption_can_be_one_of_three_type
    # "none" is already tested in the @valid_params
    entry_some_alcohol = Entry.new(@valid_params.merge(alcohol_consumption: "some"))
    assert entry_some_alcohol.valid?

    entry_much_alcohol = Entry.new(@valid_params.merge(alcohol_consumption: "much"))
    assert entry_much_alcohol.valid?
  end

  def test_alcohol_consumption_must_have_specific_value
    entry = Entry.new(@valid_params.merge(alcohol_consumption: "blob"))
    refute entry.valid?
  end

  def test_sport_can_be_empty_string
    entry = Entry.new(@valid_params.merge(sport: ""))
    assert entry.valid?
  end

  def test_sport_cannot_be_nil
    entry_1 = Entry.new(@valid_params.merge(sport: nil))
    refute entry_1.valid?

    entry_2 = Entry.new(@valid_params.except(:sport))
    refute entry_2.valid?
  end

  def test_sport_can_be_one_of_three_type
    # "none" is already tested in the @valid_params
    entry_some_sport = Entry.new(@valid_params.merge(sport: "some"))
    assert entry_some_sport.valid?

    entry_much_sport = Entry.new(@valid_params.merge(sport: "much"))
    assert entry_much_sport.valid?
  end

  def test_sport_must_have_specific_value
    entry = Entry.new(@valid_params.merge(sport: "blob"))
    refute entry.valid?
  end

  def test_account_id_must_be_integer
    entry = Entry.new(@valid_params.merge(account_id: "One"))
    refute entry.valid?
    assert entry.errors.has_key?(:account_id)
  end

  def test_batch_id_must_be_integer
    entry = Entry.new(@valid_params.merge(batch_id: "One"))
    refute entry.valid?
    assert entry.errors.has_key?(:batch_id)
  end

  # def test_batch_id_must_reference_a_batch_of_current_account
  #   entry = Entry.new(@valid_params.merge(batch_id: "7777777"))
  #   refute entry.valid_batch_id?
  #   assert entry.errors.has_key?(:invalid_batch)
  # end

  def test_day_must_be_a_date
    entry = Entry.new(@valid_params.merge(day: "Not a date"))
    refute entry.valid?
    assert entry.errors.has_key?(:day)
  end

  # Because the encryption / decryption processing happens before validation,
  # it raises an error if the attribute is not a string
  def test_raise_error_if_note_before_encryption_is_not_a_string
    entry = Entry.new(@valid_params.merge(note: ["not a string"]))
    assert_raises { refute entry.valid? }
  end

  def test_raise_error_if_weight_before_encryption_is_not_a_string
    entry = Entry.new(@valid_params.merge(weight: 50.6))
    assert_raises { refute entry.valid? }
  end

  def test_raise_error_if_alcohol_consumption_is_not_a_string
    entry = Entry.new(@valid_params.merge(alcohol_consumption: 123))
    assert_raises { refute entry.valid? }
  end

  def test_raise_error_if_sport_is_not_a_string
    entry = Entry.new(@valid_params.merge(sport: 123))
    assert_raises { refute entry.valid? }
  end

  def test_note_must_be_less_or_equal_than_600_characters
    entry = Entry.new(@valid_params.merge(note: "a" * 601))
    refute entry.valid?
    assert entry.errors.has_key?(:note)
  end

  def test_only_one_entry_per_day_per_user
    Entry.new(@valid_params).save
    entry = Entry.new(@valid_params)
    refute entry.valid?
    assert_equal 1, entry.errors.size
  end

  def test_can_be_serialized_in_json
    entry = Entry.new(@valid_params)
    assert_respond_to entry, :to_json
  end

  def test_entry_encrypted_attributes_are_stored_encrypted_but_can_be_accessed_unecrypted
    assert_equal 0, Entry.all.size
    Entry.new(@valid_params).save
    refute_equal @valid_params[:note], DB[:entries].first[:note]
    refute_equal @valid_params[:alcohol_consumption], DB[:entries].first[:alcohol_consumption]
    refute_equal @valid_params[:sport], DB[:entries].first[:sport]
    assert DB[:entries].first[:note].size >= 65
    assert DB[:entries].first[:alcohol_consumption].size >= 65
    assert DB[:entries].first[:sport].size >= 65
    assert_equal @valid_params[:note], Entry.first.note
    assert_equal @valid_params[:alcohol_consumption], Entry.first.alcohol_consumption
    assert_equal @valid_params[:sport], Entry.first.sport
  end
end

class EntryQueryingTest < HookedTestClass
  def load_fixtures
    Account.insert(user_name: "Alice", email: "alice@example.com",
      # password = 'foobar'
      password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva")

    Batch.new(account_id: 1, active: false, name: "Batch 1").save
    Batch.new(account_id: 1, active: true, name: "Batch 2", target: "49.0").save

    # Batch 1
    Entry.new(day: "2020-12-01", weight: "51.0", alcohol_consumption: "none", sport: "some", note: "", account_id: 1, batch_id: 1).save
    Entry.new(day: "2020-12-02", weight: "52.0", alcohol_consumption: "some", sport: "none", note: "", account_id: 1, batch_id: 1).save

    # Batch 2
    Entry.new(day: "2021-01-01", weight: "50.0", alcohol_consumption: "none", sport: "none", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2021-01-02", weight: "51.0", alcohol_consumption: "some", sport: "much", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2021-01-03", weight: "50.5", alcohol_consumption: "much", sport: "some", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2021-01-04", weight: "49.1", alcohol_consumption: "none", sport: "none", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2021-01-05", weight: "48.5", alcohol_consumption: "none", sport: "some", note: "", account_id: 1, batch_id: 2).save
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
      super
    end
  end

  def test_most_recent_weight
    assert_equal 48.5, Entry.most_recent_weight(1)
  end

  def test_all_results
    results = Entry.all_desc(account_id: 1, batch_id: "all")
    assert_equal Date.parse("2021-01-05"), results.first.day
    assert_equal Date.parse("2020-12-01"), results.last.day
  end

  def test_all_with_deltas_computes_correct_deltas_when_selecting_all_entries
    results = Entry.all_with_deltas(account_id: 1, batch_id: "all", batch_target: 49.0)

    assert_equal 0, results.last.delta
    assert_equal 1, results[-2].delta

    assert_equal(-2, results[-3].delta)
    assert_equal 1, results[-4].delta
    assert_equal(-0.5, results[-5].delta)
    assert_equal(-1.4, results[-6].delta)
    assert_equal(-0.6, results[-7].delta)
  end

  def test_all_with_deltas_computes_correct_deltas_when_selecting_individuel_batches
    active_batch_id = Batch.where(account_id: 1, active: true).first.id
    inactive_batch_id = Batch.where(account_id: 1, active: false).first.id

    inactive_results = Entry.all_with_deltas(account_id: 1, batch_id: inactive_batch_id, batch_target: 0.0)

    assert_equal 0, inactive_results.last.delta
    assert_equal 1, inactive_results[-2].delta

    active_results = Entry.all_with_deltas(account_id: 1, batch_id: active_batch_id, batch_target: 0.0)

    assert_equal 0, active_results.last.delta
    assert_equal 1, active_results[-2].delta
    assert_equal(-0.5, active_results[-3].delta)
    assert_equal(-1.4, active_results[-4].delta)
    assert_equal(-0.6, active_results.first.delta)
  end

  def test_all_with_deltas_computes_correct_deltas_to_target_if_target_is_present_for_specific_batch
    batch_id = Batch.where(account_id: 1, active: true).first.id
    results = Entry.all_with_deltas(account_id: 1, batch_id: batch_id, batch_target: 49.0)

    assert_equal 1.0, results.last.delta_to_target
    assert_equal 2.0, results[-2].delta_to_target
    assert_equal 1.5, results[-3].delta_to_target
    assert_equal 0.1, results[-4].delta_to_target
    assert_equal(-0.5, results[-5].delta_to_target)
  end

  def test_all_with_deltas_sets_a_slash_as_target_to_delta_if_no_target_set_for_specific_batch
    batch_id = Batch.where(account_id: 1, active: false).first.id # passive batch has no target
    results = Entry.all_with_deltas(account_id: 1, batch_id: batch_id, batch_target: 0.0)

    # check only the most ancient entries that belongs to first (inactive) batch with no target
    assert_equal "/", results.last.delta_to_target
    assert_equal "/", results[-2].delta_to_target
  end

  def test_all_with_deltas_computes_delta_to_target_or_set_slash_when_viewing_all_batches
    results = Entry.all_with_deltas(account_id: 1, batch_id: "all", batch_target: nil)

    assert_equal "/", results.last.delta_to_target
    assert_equal "/", results[-2].delta_to_target

    assert_equal 1.0, results[-3].delta_to_target
    assert_equal 2.0, results[-4].delta_to_target
    assert_equal 1.5, results[-5].delta_to_target
    assert_equal 0.1, results[-6].delta_to_target
    assert_equal(-0.5, results[-7].delta_to_target)
  end

  def test_add_bmi
    height = "170"
    Mensuration.new(account_id: 1, height: height).save
    batch_id = Batch.where(account_id: 1, active: true).first.id
    results = Entry.all_with_deltas(account_id: 1, batch_id: batch_id, batch_target: 49.0)
    results_with_bmi = Entry.add_bmi!(results, height)

    assert_equal 16.8, results_with_bmi.first.bmi
    assert_equal 17.0, results_with_bmi[1].bmi
    assert_equal 17.5, results_with_bmi[2].bmi
    assert_equal 17.6, results_with_bmi[3].bmi
    assert_equal 17.3, results_with_bmi[4].bmi
  end
end
