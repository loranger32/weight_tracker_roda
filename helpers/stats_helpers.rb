class Stats
  DAYS = {0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday",
          5 => "Friday", 6 => "Saturday"}

  attr_reader :target, :min_bmi, :max_bmi, :min_weight, :max_weight

  def initialize(entries, target)
    @entries = entries
    @target = target
    @min_bmi, @max_bmi = retrieve_minmax_bmi
    @min_weight, @max_weight = retrieve_minmax_weight
    @deltas = entries.map(&:delta)
    @losses, @gains = @deltas.partition { _1 < 0.0 }
    @total_days = total_days
  end

  def average_loss_per_day
    (@deltas.reduce(:+) / (@entries.size - 1)).round(2)
  end

  def best_day_of_week
    max_loss = sums_of_delta_per_day_of_week.map(&:values).flatten.min
    best_day = sums_of_delta_per_day_of_week.select { _1.values[0] == max_loss }[0]
    "#{DAYS[best_day.keys[0]]} : #{best_day.values[0].round(1)} (~ #{(max_loss / number_entries_for_day(best_day.keys[0])).round(1)})"
  end

  def biggest_daily_gain = "+#{@deltas.max}"

  def biggest_daily_loss = @deltas.min.to_s

  def estimated_time_to_target
    return {content: "No target specified", class: "bg-info"} if @target == 0.0

    return {content: "Not losing weight", class: "bg-danger"} if average_loss_per_day >= 0

    {content: _estimated_time_to_target.to_s + " days", class: "bg-success"}
  end

  def total_days
    entry_days = @entries.map(&:day)
    entry_days.first.downto(entry_days.last).count
  end

  def total_gain
    if no_gain_or_first_entry?
      "/"
    else
      "+#{@gains.reduce(:+).round(1)}"
    end
  end

  def total_loss = @losses.empty? ? "/" : @losses.reduce(:+).round(1).to_s

  def worst_day_of_week
    min_loss = sums_of_delta_per_day_of_week.map(&:values).flatten.max
    worst_day = sums_of_delta_per_day_of_week.select { _1.values[0] == min_loss }[0]
    "#{DAYS[worst_day.keys[0]]} : #{worst_day.values[0].round(1)} (~ #{(min_loss / number_entries_for_day(worst_day.keys[0])).round(1)})"
  end

  private

  def entries_per_day = @entries.group_by { |entry| entry.day.wday }

  def _estimated_time_to_target
    # Need to work with integers to avoid FloatDomainError
    (remaining_weight_lo_loose / (average_loss_per_day * 100).to_i).abs
  end

  def no_gain_or_first_entry? = @gains.empty? || (@gains.size == 1 && @gains[0] == 0)

  def number_entries_for_day(day) = entries_per_day[day].length

  def remaining_weight_lo_loose
    ((@entries.first.weight.to_f * 100).to_i - (@target * 100).to_i)
  end

  def retrieve_minmax_bmi = @entries.map(&:bmi).minmax

  def retrieve_minmax_weight = @entries.map(&:weight).minmax

  def sums_of_delta_per_day_of_week
    entries_per_day.map do |k, v|
      {k => v.reduce(0) { |acc, entry| acc + entry.delta }}
    end
  end
end
