require_relative "../test_helpers"

class AccountTest < HookedTestClass
  def before_all
    super
    clean_test_db!
    @valid_params = {user_name: "Alice", email: "alice@example.com",
                     # password = 'foobar'
                     password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva"}
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

  def test_has_user_name_email_pw_hash_attributes
    account = Account.new(@valid_params)
    assert_equal "Alice", account.user_name
    assert_equal "alice@example.com", account.email
    assert_equal "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva",
      account.password_hash
  end

  def test_has_an_entry_association
    assert_respond_to(Account.new, :entries)
  end

  def test_is_valid_with_valid_params
    assert Account.new(@valid_params).valid?
  end

  def test_user_name_is_required
    account = Account.new(@valid_params.except(:user_name))
    refute account.valid?
    assert account.errors.has_key?(:user_name)
  end

  def test_email_is_required
    account = Account.new(@valid_params.except(:email))
    refute account.valid?
    assert account.errors.has_key?(:email)
  end

  def test_password_hash_is_required
    account = Account.new(@valid_params.except(:password_hash))
    refute account.valid?
    assert account.errors.has_key?(:password_hash)
  end

  def test_email_must_be_unique
    Account.insert(@valid_params)
    account = Account.new(@valid_params)
    refute account.valid?
    assert account.errors.has_key?(:email)
  end

  def test_email_must_have_valid_format
    account = Account.new(@valid_params.merge(email: "invalid@com"))
    refute account.valid?
    assert account.errors.has_key?(:email)
  end

  def test_user_name_must_have_at_least_three_caharacters
    account = Account.new(@valid_params.merge(user_name: "jo"))
    refute account.valid?
    assert account.errors.has_key?(:user_name)
  end

  def test_user_name_must_have_less_or_equal_than_100_caharacters
    account = Account.new(@valid_params.merge(user_name: "jo" * 51))
    refute account.valid?
    assert account.errors.has_key?(:user_name)
  end
end
