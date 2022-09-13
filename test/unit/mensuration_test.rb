require_relative "../test_helpers"

class MensurationTest < HookedTestClass
  def load_fixtures
    Account.new(user_name: "Alice", email: "alice@example.com",
      # password = 'foobar'
      password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva").save
    Batch.new(account_id: 1, active: true, name: "Batch 1", target: "50.0").save
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

  def test_mensuration_can_be_initialized_with_valid_params
    assert Mensuration.new(account_id: 1, height: "180").valid?
  end

  def test_mensuration_has_an_account_association
    mensuration = Mensuration.new(account_id: 1, height: "180")
    assert_equal 1, mensuration.account.id
  end

  # Because the encryption / decryption processing happens before validation,
  # it raises an error if the attribute is not a string
  def test_raise_error_if_height_before_encryption_is_not_a_string
    mensuration = Mensuration.new(account_id: 1, height: 180)
    assert_raises { refute entry.valid? }
  end

  def test_account_id_must_be_present
    refute Mensuration.new(height: "180").valid?
  end

  def test_account_id_must_be_an_integer
    refute Mensuration.new(account_id: "one", height: "180").valid?
  end

  def test_height_is_preset_to_0_if_nil_or_empty_string
    mensuration_nil = Mensuration.new(account_id: 1)
    assert mensuration_nil.valid?
    assert_equal "0", mensuration_nil.height

    mensuration_blank = Mensuration.new(account_id: 1, height: "")
    assert mensuration_blank.valid?
    assert_equal "0", mensuration_blank.height
  end

  def test_height_is_encrypted_in_the_database
    mensuration = Mensuration.new(account_id: 1, height: "180").save
    refute_equal "180", DB[:mensurations].where(account_id: 1).all.first[:height]
  end

  def test_mensurations_must_be_unique_for_account
    Mensuration.new(account_id: 1, height: "150").save
    refute Mensuration.new(account_id: 1, height: "150").valid?
  end
end
