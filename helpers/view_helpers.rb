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

  def format_delta(delta)
    delta > 0 ? "+#{delta}" : delta.to_s
  end
end
end
