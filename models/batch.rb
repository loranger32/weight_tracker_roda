class Batch < Sequel::Model
  plugin :validation_helpers

  one_to_many :entries
  many_to_one :account

  def self.of_account(account_id)
    Batch.where(account_id: account_id).all
  end

  def self.active_for_account(account_id)
    active_batch = Batch.where(account_id: account_id, active: true).all

    unless active_batch.length == 1
      raise StandardError, "Must have one and only one active batch, got #{active_batch.length}"
    end
    
    active_batch.first
  end

  def validate
    super
    validates_presence [:account_id, :active]
    validates_integer :account_id
    # TO DO : active param is always evaluated in a boolean context, which means it's always true or false
    # Validation should be more specific
    validates_type [TrueClass, FalseClass], :active
    errors.add(:name, 'must have 30 characters max') if name && name.length > 30

  end

  def display_name
    return name if name

    if batch_entries_date.empty?
      Time.now.strftime("%d %b %Y") + " - ..."
    elsif !active
      first_date + " - " + last_date
    else
      first_date + " - ..."
    end
  end

  def first_date
    batch_entries_date.first
  end

  def last_date
    batch_entries_date.last
  end

  def batch_entries_date
    @batch_entries_date ||= entries.sort_by(&:day).map { |entry| entry.day.strftime("%d %b %Y") }
  end

  def set_active_status(bool_flag)
    return if bool_flag && active

    if bool_flag
      Batch.active_for_account(account_id).update(active: false)
      set(active: true)
    end
  end
end
