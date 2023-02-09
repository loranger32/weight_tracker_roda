module ViewHelpers
  def activity_types
    Entry::ACTIVITY_TYPE
  end

  def alcohol_select_option(type)
    return "Unknown" unless Entry::ACTIVITY_TYPE.include?(type)

    if type == "none"
      "No Alcohol"
    else
      type.capitalize + " Alcohol"
    end
  end

  def alcohol_sign(type)
    case type
    when "none" then "🟢"
    when "some" then "🟠"
    when "much" then "🔴"
    else
      "⚪"
    end
  end

  def batch_link(current_batch)
    return "/entries/index" unless current_batch
    "/entries?batch_id=#{current_batch.id}"
  end

  def set_page_title(title)
    if title.nil? || title.empty?
      "Weight Tracker"
    else
      "WT - #{title}"
    end
  end

  def sport_select_option(type)
    return "Unknown" unless Entry::ACTIVITY_TYPE.include?(type)

    if type == "none"
      "No Sport"
    else
      type.capitalize + " Sport"
    end
  end

  def sport_sign(type)
    case type
    when "none" then "🔴"
    when "some" then "🟠"
    when "much" then "🟢"
    else
      "⚪"
    end
  end

  def weight_delta_color(delta)
    if delta == 0
      "text-primary"
    elsif delta > 0
      "text-danger"
    else
      "text-success"
    end
  end

  def create_or_update_entry_action(entry)
    entry.new? ? "/entries" : "/entries/#{entry.id}"
  end

  def create_or_update_back_to_entries_link(entry)
    entry.new? ? "/entries" : "/entries?batch_id=#{entry.batch_id}"
  end

  def update_action?(entry)
    entry.new?
  end

  def format_delta(delta) = delta > 0 ? "+#{delta}" : delta.to_s

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

  def truncate(str, index) = str.length <= index ? str : str[0..index] + "..."

  def pluralize_batches(number_of_batches)
    word = number_of_batches == 1 ? "Batch" : "Batches"
    "#{number_of_batches} #{word}"
  end

  def pluralize_entries(number_of_entries)
    word = number_of_entries == 1 ? "Entry" : "Entries"
    "#{number_of_entries} #{word}"
  end

  def entry_highlight?(day) = day.saturday? || day.sunday?

  def is_current_batch?(current_batch, batch_info) = current_batch.name == batch_info[:name]
end
