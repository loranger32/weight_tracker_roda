class Account < Sequel::Model
  plugin :validation_helpers

  one_to_many :entries
  one_to_many :batches
  one_to_one :admin

  def self.verified
    where(status_id: 2).all
  end

  def self.unverified
    where(status_id: 1).all
  end

  def self.closed
    where(status_id: 3).all
  end

  def self.otp_on
    otp_on_account_ids = DB[:account_otp_keys].select_map(:id)
    where(id: otp_on_account_ids).all
  end

  def self.otp_off
    otp_on_account_ids = DB[:account_otp_keys].select_map(:id)
    exclude(id: otp_on_account_ids).all
  end

  def validate
    super
    validates_presence [:user_name, :email, :password_hash]
    validates_unique :email
    validates_format /^[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+$/, :email, message: "is not a valid email"
    validates_min_length 3, :user_name, message: "must have at least 3 characters"
    validates_max_length 100, :user_name
  end

  def is_admin?
    !admin.nil?
  end

  def active_batch_id
    active_batch = batches_dataset.where(active: true).all
    
    # Temporary error - must be dealt with by user on appropriate page
    raise StandardError, "More than one active batch" if active_batch.length > 1

    active_batch.first ? active_batch.first.id : nil
  end

  def active_batch_id_or_create
    active_batch_id || add_batch(active: true).id
  end
end
