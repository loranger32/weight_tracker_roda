require_relative "../test_helpers"

class MensurationManagementTest < CapybaraTestCase
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
      @alice_account = create_and_verify_account!
      super
    end
  end

  def test_height_is_set_to_zero_by_default
    assert_equal "0", @alice_account.mensuration.height

    visit "/account"
    assert_current_path "/account"
    assert_link "0 cm", href: "/mensurations"
  end

  def test_can_update_height
    visit "/account"
    click_link "0 cm"

    assert_current_path "/mensurations"
  end
end
