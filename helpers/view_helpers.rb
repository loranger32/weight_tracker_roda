module WeightTracker
  module ViewHelpers
    def set_page_title(title)
      if title.nil? || title.empty?
        "Weight Tracker"
      else
        "WT - #{title}"
      end
    end

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

    def account_cancel_link
      rodauth.authenticated? ? "/account" : "/"
    end

    def format_auth_log_action(action)
      case action
      when "login" then "bg-success"
      when "logout" then "bg-warning"
      when "login_failure" then "bg-danger"
      else
        "bg-secondary"
      end
    end

    def entries_index_batch_badge_infos(batch_info)
      if batch_info[:target]
        "#{batch_info[:name]}\n #{batch_info[:target]}"
      else
        batch_info[:name]
      end
    end
  end
end
