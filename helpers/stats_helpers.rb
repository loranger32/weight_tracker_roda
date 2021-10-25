module WeightTracker
  class Stats
    DAYS = {0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday",
            5 => "Friday", 6 => "Saturday"}

    def initialize(entries, target)
      @entries = entries
      @target = target
      @deltas = entries.map(&:delta)
      @losses, @gains = @deltas.partition { _1 < 0.0 }
      @total_days = total_days
    end

    def biggest_gain
      "+ #{@deltas.max}"
    end

    def biggest_loss
      @deltas.min
    end

    def total_loss
      @losses.reduce(:+).round(1)
    end

    def total_gain
      "+ #{@gains.reduce(:+).round(1)}"
    end

    def best_day_of_week
      max_loss = sums_of_delta_per_day_of_week.map(&:values).flatten.min
      best_day = sums_of_delta_per_day_of_week.select {  _1.values[0] == max_loss }[0]
      "#{DAYS[best_day.keys[0]]} : #{best_day.values[0].round(1)} (~ #{(max_loss / number_entries_for_day(best_day.keys[0])).round(1)})"
    end

    def worst_day_of_week
      min_loss = sums_of_delta_per_day_of_week.map(&:values).flatten.max
      worst_day = sums_of_delta_per_day_of_week.select {  _1.values[0] == min_loss }[0]
      "#{DAYS[worst_day.keys[0]]} : #{worst_day.values[0].round(1)} (~ #{(min_loss / number_entries_for_day(worst_day.keys[0])).round(1)})"
    end

    def average_loss_per_day
      (@deltas.reduce(:+) / @total_days).round(1)
    end

    def total_days
      entry_days = @entries.map(&:day)
      entry_days.first.downto(entry_days.last).count
    end

    # TODO : find appropriate indication when displaying all batches
    def estimated_time_to_target
      ((@entries.first.weight.to_f - @target) / average_loss_per_day).ceil.abs.to_s + " days"
    end

    private

      def number_entries_for_day(day)
        entries_per_day[day].length
      end

      def entries_per_day
        @entries.group_by { |entry| entry.day.wday }
      end

      def sums_of_delta_per_day_of_week
        entries_per_day.map do |k, v|
          {k => v.reduce(0) { |acc, entry| acc += entry.delta }}
        end
      end
  end
end