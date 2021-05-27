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

    def ensure_at_least_one_batch_for_account!(account_id)
      return if Batch.of_account(account_id).length > 0

      Account[account_id].add_batch(active: true)
    end

    def account_owns_batch?(account, batch_id)
      account.batches.map(&:id).include? batch_id
    end
  end
end
