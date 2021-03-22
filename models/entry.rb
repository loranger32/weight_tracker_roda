class Entry < Sequel::Model
  plugin :validation_helpers

  many_to_one :account

  attr_accessor :delta

  def self.all_desc(account_id)
    where(account_id: account_id).reverse_order(:day).all
  end

  def self.most_recent_weight(account_id)
    if (most_recent = all_desc(account_id).first)
      most_recent.weight.to_f
    end
  end

  def self.all_desc_with_deltas(account_id)
    entries = all_desc(account_id)
    entries.each_with_index do |entry, index|
      if entries[index + 1]
        entry.delta = (entry.weight - entries[index + 1].weight).to_f
      else
        entry.delta = 0
      end
    end 
  end

  def validate
    super
    validates_presence [:day, :weight, :account_id]
    validates_integer :account_id
    validates_type Date, :day
    validates_numeric :weight
    validates_type String, :note
    validates_max_length 600, :note
    validates_unique [:day, :account_id], message: "Can't have two entries for the same day"
  end
end
