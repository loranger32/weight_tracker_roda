module WeightTracker
  class Stats
    def initialize(entries)
      @entries = entries
      @deltas = entries.map(&:delta)
      @losses, @gains = @deltas.partition { _1 < 0.0 }
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

    end

    def worst_day_of_week
    end

    def average_loss_per_day

    end

    def estimated_time_to_target
    end
  end
end