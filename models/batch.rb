class Batch < Sequel::Model
  plugin :validation_helpers
  plugin :json_serializer
  plugin :column_encryption do |enc|
    enc.column :target
  end

  one_to_many :entries
  many_to_one :account

  def self.of_account(account_id)
    Batch.where(account_id: account_id).all
  end

  def self.active_for_account(account_id)
    Batch.where(account_id: account_id, active: true).all
  end

  def before_validation
    self.target = "0.0" if target == "" || target.nil?
    self.name = "New Batch" if name == "" || name.nil?
    super
  end

  def validate
    super
    validates_presence [:account_id, :active, :name, :target]
    validates_integer :account_id
    # TO DO : active param is always evaluated in a boolean context, which means it's always true or false
    # Validation should be more specific
    validates_type [TrueClass, FalseClass], :active
    validates_type String, :name
    validates_type String, :target
    errors.add(:name, "must have 30 characters max") if name && name.length > 30
  end

  def first_date
    batch_entries_date.first
  end

  def last_date
    batch_entries_date.last
  end

  def set_active_status
    return if active

    Batch.active_for_account(account_id).map { |batch| batch.update(active: false) }
    set(active: true)
  end

  private

  def batch_entries_date
    @batch_entries_date ||= entries.sort_by(&:day).map { |entry| entry.day.strftime("%d %b %Y") }
  end
end
