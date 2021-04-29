module WeightTracker
  module AppHelpers
    def format_flash_error(model)
      if model.errors.length >= 2
        model.errors.full_messages.map { |msg| "- #{msg}" }.join("\n")
      else
        model.errors.full_messages[0]
      end
    end

    def valid_weight_string?(weight)
      weight.match?(/\A\d{2,3}[\,|\.]\d\z/)
    end
  end
end
