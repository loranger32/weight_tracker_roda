module WeightTracker
  module AppHelpers
    def format_flash_error(model)
      if model.errors.length >= 2
        model.errors.full_messages.map { |msg| "- #{msg}" }.join("\n")
      else
        model.errors.full_messages[0]
      end
    end

    def valid_weight_string?(weight) = weight.match?(/\A\d{2,3}[\,|\.]\d\z/)

    def valid_height?(height) = height != 0 && height < 250 && height > 50

    def ensure_at_least_one_batch_for_account!(account_id)
      return if Batch.of_account(account_id).length > 0

      Account[account_id].add_batch(active: true)
    end

    def ensure_mensuration_is_setup_for_account(account_id)
      Mensuration.create(account_id: account_id, height: "") unless Account[account_id].mensuration
    end

    def account_owns_batch?(account, batch_id) = account.batches.map(&:id).include? batch_id

    def landing_page(account_ds)
      Account[account_ds[:id]].has_entry_for_today? ? "/entries" : "/entries/new"
    end
  end
end
