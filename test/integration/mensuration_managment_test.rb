require_relative "../test_helpers"

class MensurationManagementTest < CapybaraTestCase
  def before_all
    super
    clean_test_db!
    @alice_account = create_and_verify_account!
    login!
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

  def test_height_is_set_to_zero_by_default
    assert_equal "0", Mensuration.where(account_id: @alice_account.id).first.height

    visit "/account"
    assert_current_path "/account"
    assert_link "0 cm", href: "/mensurations"
  end

  def test_can_update_height
    visit "/account"
    click_link "0 cm"

    assert_current_path "/mensurations"
    assert_content "Height (cm)"
    fill_in "Height (cm)", with: "170"
    click_on "Update"

    assert_current_path "/account"
    assert_css ".alert-success"
    assert_content "Mensuration successfully submitted"
    assert_link "170 cm", href: "/mensurations"
    assert_equal "170", Mensuration.where(account_id: @alice_account.id).first.height
  end
end
