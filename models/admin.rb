class Admin < Sequel::Model
  plugin :validation_helpers

  many_to_one :account

  def validate
    validates_presence [:account_id]
    validates_integer :account_id
    validates_unique :account_id
    super
  end
end
