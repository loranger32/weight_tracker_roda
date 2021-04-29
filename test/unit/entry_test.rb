require_relative "../test_helpers"

class EntryBasicTest < HookedTestClass
  def before_all
    super
    @valid_params= {day: Date.parse("2021-01-01"), weight: "50.0", account_id: 1, note: "A good note"}
  end

  def load_fixtures
    clean_fixtures
    Account.insert(user_name: "Alice", email: "alice@example.com",
                   # password = 'foobar'
                   password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva")
  end

  def clean_fixtures
    [:entries, :accounts].each do |table|
      DB[table].delete
      DB.reset_primary_key_sequence(table)
    end
  end

  def test_has_day_weight_note_and_delta_attributes
    entry = Entry.new
    assert_respond_to(entry, :day)
    assert_respond_to(entry, :weight)
    assert_respond_to(entry, :note)
    assert_respond_to(entry, :delta)
  end

  def test_has_an_account_association
    entry = Entry.new(@valid_params)

    assert_instance_of Account, entry.account
    assert_equal "Alice", entry.account.user_name
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

  def test_note_must_be_present
    entry = Entry.new(@valid_params.except(:note))
    refute entry.valid?
    assert entry.errors.has_key?(:note)
  end

  def test_note_can_be_empty_string
    entry = Entry.new(@valid_params.merge(note: ""))
    assert entry.valid?
  end

  def test_account_id_must_be_integer
    entry = Entry.new(@valid_params.merge(account_id: "One"))
    refute entry.valid?
    assert entry.errors.has_key?(:account_id)
  end

  def test_day_must_be_a_date
    entry = Entry.new(@valid_params.merge(day: "Not a date"))
    refute entry.valid?
    assert entry.errors.has_key?(:day)
  end

  # Because the encryption / decryption processing happens before validation,
  # it raises an error if the attribute is not a string
  def test_raise_error_if_note_before_encryption_is_not_a_string
    entry = Entry.new(@valid_params.merge(note: ['not a string']))
    assert_raises { refute entry.valid? }
  end

  def test_raise_error_if_weight_before_encryption_is_not_a_string
    entry = Entry.new(@valid_params.merge(weight: 50.6))
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

  def test_can_be_serialized_in_json_csv_and_xml
    entry = Entry.new(@valid_params)
    assert_respond_to entry, :to_json
    assert_respond_to entry, :to_csv
    assert_respond_to entry, :to_xml
  end

  def test_entry_note_is_stored_encrypted_but_can_be_accessed_unecrypted
    assert_equal 0, Entry.all.size
    Entry.new(@valid_params).save
    refute_equal @valid_params[:note], DB[:entries].first[:note]
    assert DB[:entries].first[:note].size >= 65
    assert_equal @valid_params[:note], Entry.first.note 
  end
end

class EntryQueryingTest < HookedTestClass
  def load_fixtures
    clean_fixtures
    Account.insert(user_name: "Alice", email: "alice@example.com",
                   # password = 'foobar'
                   password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva") 
    Entry.new(day: "2021-01-01" , weight: "50.0", note: "", account_id: 1).save
    Entry.new(day: "2021-01-02" , weight: "51.0", note: "", account_id: 1).save
    Entry.new(day: "2021-01-03" , weight: "50.5", note: "", account_id: 1).save
    Entry.new(day: "2021-01-04" , weight: "49.1", note: "", account_id: 1).save
    Entry.new(day: "2021-01-05" , weight: "48.5", note: "", account_id: 1).save
  end

  def clean_fixtures
    [:entries, :accounts].each do |table|
      DB[table].delete
      DB.reset_primary_key_sequence(table)
    end
  end

  def test_all_desc
    results = Entry.all_desc(1)
    assert_equal Date.parse("2021-01-05"), results.first.day
    assert_equal Date.parse("2021-01-01"), results.last.day
  end

  def test_most_recent_weight
    assert_equal 48.5, Entry.most_recent_weight(1)
  end

  def test_all_desc_with_deltas
    results = Entry.all_desc_with_deltas(1)
    assert_equal 0, results.last.delta
    assert_equal 1, results[-2].delta
    assert_equal -0.5, results[-3].delta
    assert_equal -1.4, results[-4].delta
    assert_equal -0.6, results[-5].delta
  end

end
