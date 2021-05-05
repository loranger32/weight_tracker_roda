require_relative "../test_helpers"

class BatchBasicTest < HookedTestClass
  def load_fixtures
    clean_fixtures
    Account.insert(user_name: "Alice", email: "alice@example.com",
                   # password = 'foobar'
                   password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva")
    Batch.insert(account_id: 1, active: true)
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

  # TO DO : active param is always evaluated in a boolean context, which means it's always
  # true or false. Validation should be more specific
  # def test_active_must_be_boolean
  #   batch = Batch.new(account_id: 1, active: :no)
  #   refute batch.valid?
  #   assert batch.errors.has_key?(:active)
  # end
end
