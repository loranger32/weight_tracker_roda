require_relative "../test_helpers"

class AdminTest < HookedTestClass
  def before_all
    super
    clean_test_db!
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      @alice_account = Account.new(user_name: "Alice", email: "alice@example.com",
        # password = 'foobar'
        password_hash: "$2a$04$xRFEJH568qcg4ycFRaUKnOgY2Nm1WQqOaFyQtkGLh95s9Fl9/GCva").save
      super
    end
  end

  def test_admin_can_be_initialized_with_valid_params
    assert Admin.new(account_id: @alice_account.id).valid?
  end

  def test_account_id_must_be_an_integer
    refute Admin.new(account_id: "one").valid?
  end

  def test_account_id_must_be_unique
    Admin.new(account_id: @alice_account.id).save
    refute Admin.new(account_id: @alice_account.id).valid?
  end
end
