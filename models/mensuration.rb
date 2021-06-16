class Mensuration < Sequel::Model
  plugin :validation_helpers
  plugin :column_encryption do |enc|
    enc.column :height
  end

  many_to_one :account

  def validate
    super
    validates_presence [:account_id, :height]
    validates_integer :account_id
    validates_type String, :height
  end

  def before_validation
    self.height == "0.0" if (height == "" || height.nil?)
    super
  end
end
