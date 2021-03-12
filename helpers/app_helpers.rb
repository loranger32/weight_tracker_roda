module WeightTracker
class App
  def validate_entry_params(params)
    errors = []
    errors << validate_weight(params[:weight])
    errors << validate_day(params[:day])
    errors << validate_note(params[:note])
    errors.compact
  end

  def validate_weight(weight)
    "Weight is invalid" unless weight.is_a?(Float) && weight > 50.0 && weight < 200.0
  end

  def validate_day(day)
    "Date is invalid" unless day.is_a?(Date)
  end

  def validate_note(note)
    "Note is invalid" unless note.is_a?(String) && note.size < 600
  end
end
end
