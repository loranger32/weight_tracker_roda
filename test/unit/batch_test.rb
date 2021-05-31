require_relative "../test_helpers"

class BatchBasicTest < HookedTestClass
  def load_fixtures
    clean_fixtures
    Account.insert(user_name: "Alice", email: "alice@example.com",
                   # password = 'foobar'
                   password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva")
    Batch.new(account_id: 1, active: true, name: "Batch 1", target: "50.0").save
    Entry.new(day: "2020-12-01" , weight: "51.0", note: "", account_id: 1, batch_id: 1).save
    Entry.new(day: "2020-12-02" , weight: "52.0", note: "", account_id: 1, batch_id: 1).save
  end

  def clean_fixtures
    [:batches, :entries, :accounts].each do |table|
      DB[table].delete
      DB.reset_primary_key_sequence(table)
    end
  end

  def test_has_db_columns_accessors
    batch = Batch.new
    assert_respond_to(batch, :id)
    assert_respond_to(batch, :account_id)
    assert_respond_to(batch, :active)
    assert_respond_to(batch, :name)
    assert_respond_to(batch, :target)
  end

  def test_has_an_account_association
    batch = Batch[1]
    assert_instance_of Account, batch.account
    assert_equal "Alice", batch.account.user_name
  end

  def test_has_an_entries_association
    batch = Batch[1]
    assert_equal 2, batch.entries.length
    assert_instance_of Entry, batch.entries.first
  end

  def test_account_id_must_be_present
    batch = Batch.new(active: true)
    refute batch.valid?
    assert batch.errors.has_key?(:account_id)
  end

  def test_active_must_be_present
    batch = Batch.new(account_id: 1)
    refute batch.valid?
    assert batch.errors.has_key?(:active)
  end

  def test_account_id_must_be_integer
    batch = Batch.new(account_id: "one", active: true)
    refute batch.valid?
    assert batch.errors.has_key?(:account_id)
  end

  def test_name_must_have_max_length_of_30
    batch = Batch.new(account_id: 1, active: true, name: "a" * 31)
    refute batch.valid?
    assert batch.errors.has_key?(:name)
  end

  # Because the encryption / decryption processing happens before validation,
  # it raises an error if the attribute is not a string
  def test_raise_error_if_target_before_encryption_is_not_a_string
    entry = Batch.new(account_id: 1, active: true, name: "Test Batch", target: ["50.0"])
    assert_raises { refute entry.valid? }
  end

  def test_target_is_encrypted_in_database
    encrypted_target = Batch.where(id: 1).first[:target]
    refute_equal "50.0", encrypted_target
    assert encrypted_target.length > 90
  end

  def test_target_can_be_decrypted
    assert_equal "50.0", Batch[1].target
  end

  def test_target_can_be_empty_string
    batch = Batch.new(account_id: 1, active: true, name: "Test Batch", target: "")
    assert batch.valid?
  end

  def test_target_can_be_nil
    batch = Batch.new(account_id: 1, active: true, name: "Test Batch")
    assert batch.valid?
  end


  # TO DO : active param is always evaluated in a boolean context, which means it's always
  # true or false. Validation should be more specific
  # def test_active_must_be_boolean
  #   batch = Batch.new(account_id: 1, active: :no)
  #   refute batch.valid?
  #   assert batch.errors.has_key?(:active)
  # end
end

class BatchAdvancedTest < HookedTestClass
  def load_fixtures
    clean_fixtures
    Account.insert(user_name: "Alice", email: "alice@example.com",
                   # password = 'foobar'
                   password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva")

    Batch.new(account_id: 1, active: false, name: "non active").save
    Batch.new(account_id: 1, active: true, name: "active one").save

    # Cannot use insert here beacuse of the column encryption
    Entry.new(day: "2020-11-01" , weight: "51.0", note: "", account_id: 1, batch_id: 1).save
    Entry.new(day: "2020-11-02" , weight: "54.0", note: "", account_id: 1, batch_id: 1).save
    Entry.new(day: "2020-12-01" , weight: "51.0", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2020-12-02" , weight: "52.0", note: "", account_id: 1, batch_id: 2).save
    Entry.new(day: "2020-12-03" , weight: "53.0", note: "", account_id: 1, batch_id: 2).save

    @account = Account.where(user_name: "Alice").first
  end

  def clean_fixtures
    [:batches, :entries, :accounts].each do |table|
      DB[table].delete
      DB.reset_primary_key_sequence(table)
    end
  end

  def teardown
    # Only needed for the last test
    Batch.where(name: "active one").update(active: true)
    Batch.where(name: "non active").update(active: false)
  end

  def test_batch_of_account_returns_all_batches_for_given_account
    actual = Batch.of_account(@account.id)

    assert_instance_of Array, actual
    assert_equal 2, actual.length
    actual.each { |batch| assert_instance_of Batch, batch }
  end

  def test_batch_active_for_account_returns_all_active_batches_for_given_account
    actual = Batch.active_for_account(@account.id)
    
    assert_instance_of Array, actual
    assert_equal 1, actual.length
    actual.each { |batch| assert_instance_of Batch, batch }
    assert_equal "active one", actual.first.name
  end

  def test_set_a_default_name_if_is_nil
    batch = @account.add_batch(active: true)
    assert_equal "New Batch", batch.name
  end


  def test_set_a_default_name_if_is_empty_string
    batch = @account.add_batch(active: true, name: "")
    assert_equal "New Batch", batch.name
  end

  def test_has_a_first_date
    actual = Batch.active_for_account(@account.id).first.first_date
    excpected = "01 Dec 2020"

    assert_equal excpected, actual
  end

  def test_batch_has_a_last_date
    actual = Batch.where(name: "non active").first.last_date
    excpected = "02 Nov 2020"

    assert_equal excpected, actual
  end

  def test_set_active_status
    # Be sure that the preconditions are met
    refute_nil first_batch  = Batch.where(name: "active one", active: true).first
    refute_nil second_batch = Batch.where(name: "non active", active: false).first

    # set_active_status does nothing if the batch is already active
    first_batch.set_active_status

    refute_nil Batch.where(name: "active one", active: true).first
    refute_nil Batch.where(name: "non active", active: false).first

    # set_active_status set status to active if not active and set others to non active
    second_batch.set_active_status

    assert_equal false, Batch.where(name: "active one").first.active
    assert_equal true, second_batch.active
    second_batch.save
    assert_equal true, Batch.where(name: "non active").first.active
  end
end
