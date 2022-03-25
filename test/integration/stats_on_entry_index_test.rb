require_relative "../test_helpers"

class StatsOnEntryIndexTest < CapybaraTestCase
  def before_all
    super
    clean_test_db!
    @alice_account = create_and_verify_account!
    @alice_account.mensuration.update(height: "160")
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always) do
      login!
      super
    end
  end

  def test_no_stats_when_only_one_entry
    visit "/entries"
    assert_content "Not enough entries to compute stats"
    refute_content "Biggest Daily Loss"

    @alice_account.add_entry(day: "2021-12-19", weight: "50.0", note: "", batch_id: 1)
    visit "/entries"

    assert_content "Not enough entries to compute stats"
    refute_content "Biggest Daily Loss"
  end

  def test_stats_when_at_least_two_entries
    visit "/entries"
    @alice_account.add_entry(day: "2021-12-19", weight: "50.0", note: "", batch_id: 1)
    @alice_account.add_entry(day: "2021-12-20", weight: "45.5", note: "", batch_id: 1)

    visit "/entries"
    refute_content "Not enough entries to compute stats"
    assert_content "Biggest Daily Loss"
  end

  def test_stats_are_accurate
    visit "/entries"

    # Add 13 entries for Alice (same data as in the unit test)
    @alice_account.add_entry(day: "2021-01-01", weight: "70.0", note: "", batch_id: 1) # Friday
    # skip 1 day
    @alice_account.add_entry(day: "2021-01-03", weight: "70.5", note: "", batch_id: 1) # Sunday
    @alice_account.add_entry(day: "2021-01-04", weight: "71.0", note: "", batch_id: 1) # Monday
    @alice_account.add_entry(day: "2021-01-05", weight: "70.5", note: "", batch_id: 1) # Tuesday
    @alice_account.add_entry(day: "2021-01-06", weight: "70.0", note: "", batch_id: 1) # Wednesday
    # Skip 3 days
    @alice_account.add_entry(day: "2021-01-10", weight: "69.5", note: "", batch_id: 1) # Sunday
    @alice_account.add_entry(day: "2021-01-11", weight: "69.0", note: "", batch_id: 1) # Monday
    @alice_account.add_entry(day: "2021-01-12", weight: "68.5", note: "", batch_id: 1) # Tuesday
    @alice_account.add_entry(day: "2021-01-13", weight: "68.0", note: "", batch_id: 1) # Wednesday
    @alice_account.add_entry(day: "2021-01-14", weight: "69.0", note: "", batch_id: 1) # Thursday
    # Skip 2 days
    @alice_account.add_entry(day: "2021-01-17", weight: "68.5", note: "", batch_id: 1) # Sunday
    @alice_account.add_entry(day: "2021-01-18", weight: "68.0", note: "", batch_id: 1) # Monday
    @alice_account.add_entry(day: "2021-01-19", weight: "67.0", note: "", batch_id: 1) # Tuesday

    visit "/entries"

    within("#stats") do
      refute_content "Not enough entries to compute stats"

      assert_content "Lowest / Highest Weight :"
      assert_content "67.0"
      assert_content "71.0"

      assert_content "Lowest / Highest BMI :"
      assert_content "26.2"
      assert_content "27.7"

      assert_content "Biggest Daily Loss / Gain :"
      assert_content "+1.0"
      assert_content "-1.0"

      assert_content "Total Loss / Gain :"
      assert_content "-5.0"
      assert_content "+2.0"

      assert_content "Best / Worst Day of Week :"
      assert_content "Tuesday : -2.0 (~ -0.7)"
      assert_content "Thursday : 1.0 (~ 1.0)"

      assert_content "Number of Entries / Number of Days :"
      assert_content "13 / 19"

      assert_content "Average Loss / Gain per Day :"
      assert_content "-0.25"

      assert_content "Estimated Time to Target"
      assert_content "No target specified"
    end

    @alice_account.batches.first.update(target: "65.0")

    visit "/entries"

    within("#stats") do
      assert_content "8 days" # estimated time to target
      refute_content "No target specified"
    end

    # Test average loss per day and estimated time to target when gain is bigger than loss
    @alice_account.add_entry(day: "2021-01-20", weight: "85.0", note: "", batch_id: 1)

    visit "/entries"

    within("#stats") do
      assert_content "+1.15" # average gain per day

      assert_content "Not losing weight" # estimated time to target
    end
  end
end
