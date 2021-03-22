class Account < Sequel::Model
  plugin :validation_helpers

  one_to_many :entries

  def validate
    super
    validates_presence [:user_name, :email, :password_hash]
    validates_unique :email
    validates_format /^[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+$/, :email, message: "is not a valid email"
    validates_min_length 3, :user_name
    validates_max_length 100, :user_name
  end
end
