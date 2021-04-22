module WeightTracker
  module AppHelpers
    # Temporary Hack
    def is_admin?(account)
      account[:id] == 3
    end

    def format_flash_error(model)
      if model.errors.length >= 2
        model.errors.full_messages.map { |msg| "- #{msg}" }.join("\n")
      else
        model.errors.full_messages[0]
      end
    end
  end
end
