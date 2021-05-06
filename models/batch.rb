class Batch < Sequel::Model
  plugin :validation_helpers

  one_to_many :entries
  many_to_one :account

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
end
