require_relative "../test_helpers"

class StatsHelperLossingWeightTest < HookedTestClass
  TEST_TARGET = 65.0

  def load_fixtures
    Account.insert(user_name: "Alice", email: "alice@example.com",
      password_hash: BCrypt::Password.create("foobar"))
    Account.insert(user_name: "Albert", email: "albert@example.com",
      password_hash: BCrypt::Password.create("helloworld"))
    Account.insert(user_name: "Bob", email: "bob@example.com",
      password_hash: BCrypt::Password.create("secret"))

    Batch.new(account_id: 1, active: true, name: "Batch 1", target: TEST_TARGET.to_s).save
    Batch.new(account_id: 2, active: true, name: "Batch 1", target: "0.0").save
    Batch.new(account_id: 3, active: true, name: "Batch 1", target: "70.0").save

    # Alice has 13 entries
    Entry.new(day: "2021-01-01", weight: "70.0", note: "", account_id: 1, batch_id: 1).save # Friday
    # Skip 1 day
    Entry.new(day: "2021-01-03", weight: "70.5", note: "", account_id: 1, batch_id: 1).save # Sunday
    Entry.new(day: "2021-01-04", weight: "71.0", note: "", account_id: 1, batch_id: 1).save # Monday
    Entry.new(day: "2021-01-05", weight: "70.5", note: "", account_id: 1, batch_id: 1).save # Tuesday
    Entry.new(day: "2021-01-06", weight: "70.0", note: "", account_id: 1, batch_id: 1).save # Wednesday
    # Skip 3 days
    Entry.new(day: "2021-01-10", weight: "69.5", note: "", account_id: 1, batch_id: 1).save # Sunday
    Entry.new(day: "2021-01-11", weight: "69.0", note: "", account_id: 1, batch_id: 1).save # Monday
    Entry.new(day: "2021-01-12", weight: "68.5", note: "", account_id: 1, batch_id: 1).save # Tuesday
    Entry.new(day: "2021-01-13", weight: "68.0", note: "", account_id: 1, batch_id: 1).save # Wednesday
    Entry.new(day: "2021-01-14", weight: "69.0", note: "", account_id: 1, batch_id: 1).save # Thursday
    # Skip 2 days
    Entry.new(day: "2021-01-17", weight: "68.5", note: "", account_id: 1, batch_id: 1).save # Sunday
    Entry.new(day: "2021-01-18", weight: "68.0", note: "", account_id: 1, batch_id: 1).save # Monday
    Entry.new(day: "2021-01-19", weight: "67.0", note: "", account_id: 1, batch_id: 1).save # Tuesday

    # Albert has 5 entries, no target and no losses
    Entry.new(day: "2021-01-01", weight: "70.0", note: "", account_id: 2, batch_id: 2).save
    Entry.new(day: "2021-01-03", weight: "70.5", note: "", account_id: 2, batch_id: 2).save
    Entry.new(day: "2021-01-04", weight: "71.0", note: "", account_id: 2, batch_id: 2).save
    Entry.new(day: "2021-01-05", weight: "71.5", note: "", account_id: 2, batch_id: 2).save
    Entry.new(day: "2021-01-06", weight: "72.0", note: "", account_id: 2, batch_id: 2).save

    # Bob has 2 entries, a target and no gain
    Entry.new(day: "2021-01-01", weight: "70.0", note: "", account_id: 3, batch_id: 3).save
    Entry.new(day: "2021-01-03", weight: "69.5", note: "", account_id: 3, batch_id: 3).save
  end

  def before_all
    super
    clean_test_db!
    load_fixtures
    @alice = Account.where(user_name: "Alice").first
    @alice_entries = Entry.all_with_deltas(account_id: 1, batch_id: 1, batch_target: 65.0)
    Entry.add_bmi!(@alice_entries, "160")
    @alice_stats = WeightTracker::Stats.new(@alice_entries, TEST_TARGET)

    @albert = Account.where(user_name: "Albert").first
    @albert_entries = Entry.all_with_deltas(account_id: 2, batch_id: 2, batch_target: 0.0)
    Entry.add_bmi!(@albert_entries, "0")
    @albert_stats = WeightTracker::Stats.new(@albert_entries, 0.0)
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

  def test_has_a_target_attribute_reader
    assert_equal TEST_TARGET, @alice_stats.target
  end

  def test_biggest_daily_gain
    assert_equal "+1.0", @alice_stats.biggest_daily_gain
  end

  def test_biggest_daily_loss
    assert_equal "-1.0", @alice_stats.biggest_daily_loss
  end

  def test_lowest_and_highest_weight
    assert_equal "67.0", @alice_stats.min_weight
    assert_equal "71.0", @alice_stats.max_weight
  end

  def test_highest_and_lowest_bmi
    # Alice has registered her mensuration (height = 160 cm)
    assert_equal 26.2, @alice_stats.min_bmi
    assert_equal 27.7, @alice_stats.max_bmi

    # Albert has registered mensuration with a height of 0
    assert_equal "/", @albert_stats.min_bmi
    assert_equal "/", @albert_stats.max_bmi

    # Bob hasn't regitered any mensuration
    bob = Account.where(user_name: "Bob").first
    bob_entries = Entry.all_with_deltas(account_id: bob.id, batch_id: 3, batch_target: 70.0)
    bob_stats = WeightTracker::Stats.new(bob_entries, 70.0)

    assert_equal "/", bob_stats.min_bmi
    assert_equal "/", bob_stats.max_bmi
  end

  def test_total_loss_when_at_least_one_loss
    assert_equal "-5.0", @alice_stats.total_loss
  end

  def test_total_gain_when_at_least_one_gain
    assert_equal "+2.0", @alice_stats.total_gain
  end

  def test_total_loss_when_no_loss
    assert_equal "/", @albert_stats.total_loss
  end

  def test_total_gain_when_no_gain
    bob = Account.where(user_name: "Bob").first
    bob_entries = Entry.all_with_deltas(account_id: bob.id, batch_id: 3, batch_target: 70.0)
    bob_stats = WeightTracker::Stats.new(bob_entries, 70.0)
    assert_equal "/", bob_stats.total_gain
  end

  def test_best_day_of_week
    assert_equal "Tuesday : -2.0 (~ -0.7)", @alice_stats.best_day_of_week
  end

  def test_worst_day_of_week
    assert_equal "Thursday : 1.0 (~ 1.0)", @alice_stats.worst_day_of_week
  end

  def test_average_loss_per_day
    # -3.0 / 12
    assert_equal(-0.25, @alice_stats.average_loss_per_day)
  end

  def test_estimated_time_to_target_when_target_is_set_and_tendence_is_good
    ett = @alice_stats.estimated_time_to_target
    assert_equal "8 days", ett[:content]
    assert_equal "bg-success", ett[:class]
  end

  def test_estimated_time_to_target_when_no_target_is_set
    albert = Account.where(user_name: "Albert").first
    albert_entries = Entry.all_with_deltas(account_id: albert.id, batch_id: 2, batch_target: 0.0)

    ett = WeightTracker::Stats.new(albert_entries, 0.0).estimated_time_to_target

    assert_equal "No target specified", ett[:content]
    assert_equal "bg-info", ett[:class]
  end
end
