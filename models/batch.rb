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
  end
end
