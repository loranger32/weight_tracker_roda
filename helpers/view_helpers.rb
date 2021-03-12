module WeightTracker
  class App
    def weight_delta_color(delta)
      if delta == 0
        "blue"
      elsif delta > 0
        "red"
      else
        "green"
      end
    end

    def create_or_update_entry_action(entry)
      entry.new? ? "/entries" : "/entries/#{entry.id}"
    end
  end
end
