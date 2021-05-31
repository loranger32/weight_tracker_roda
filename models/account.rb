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

  def self.admins
    admin_ids = Admin.select_map(:account_id)
    where(id: admin_ids).all
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

  def has_entry_for_today?
    return false if entries.empty?

    today = Time.now.strftime("%d %b %Y")
    last_entry_date = Entry.where(account_id: id).select_map(:day).sort.reverse.first.strftime("%d %b %Y")
    today == last_entry_date
  end

  def last_entry
    return if entries.empty?

    Entry.all_desc(account_id: id, batch_id: "all").first
  end

  def last_entry_date
    last_entry ? last_entry.day.strftime("%d %b %Y") : "/"
  end

  def is_verified?
    status_id == 2
  end

  def is_closed?
    status_id == 3
  end

  def is_unverified?
    status_id == 1 
  end

  def account_status
    case status_id
    when 2 then "verified"
    when 3 then "closed"
    when 1 then "unverified"
    else
      "unknown status"
    end
  end

  def before_destroy
    batches.each(&:destroy)
    super
  end
end
