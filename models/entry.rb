class Entry < Sequel::Model
  plugin :validation_helpers
  plugin :json_serializer
  plugin :column_encryption do |enc|
    enc.column :note
    enc.column :weight
  end

  many_to_one :account
  many_to_one :batch

  attr_accessor :delta, :delta_to_target, :bmi

  dataset_module do
    def all_desc(account_id:, batch_id:)
      if batch_id == "all"
        all_in_descending_order_by_date(account_id)
      else
        all_active_in_descending_order_by_date(account_id, batch_id)
      end
    end

    def all_in_descending_order_by_date(account_id)
      where(account_id: account_id).reverse_order(:day).all
    end

    def all_active_in_descending_order_by_date(account_id, batch_id)
      where(account_id: account_id, batch_id: batch_id).reverse_order(:day).all
    end

    def most_recent_weight(account_id)
      if (most_recent = all_desc(account_id: account_id, batch_id: "all").first)
        most_recent.weight.to_f
      end
    end

    def all_with_deltas(account_id:, batch_id:, batch_target:)
      entries = all_desc(account_id: account_id, batch_id: batch_id)

      add_deltas(entries)
      add_deltas_to_target(entries, batch_target)
      entries
    end

    def add_deltas(entries)
      entries.each_with_index do |entry, index|
        entry.delta = if entries[index + 1]
          (entry.weight.to_f - entries[index + 1].weight.to_f).round(1)
        else
          0
        end
      end
    end

    def add_deltas_to_target(entries, batch_target)
      entries.each do |entry|
        entry.add_delta_to_target(batch_target)
      end
    end
  end

  def self.add_bmi(entries, height)
    entries.map do |entry|
      entry.bmi = entry.compute_bmi(height)
      entry
    end
  end

  def validate
    super
    validates_presence [:day, :weight, :account_id]
    validates_presence :batch_id, message: "No active batch, please check your settings"
    validates_integer :account_id
    validates_integer :batch_id
    validates_type Date, :day
    validates_type String, :weight
    validates_type String, :note
    validates_max_length 600, :note
    validates_unique [:day, :account_id], message: "Can't have two entries for the same day"
  end

  def compute_bmi(height)
    height == "0" ? "/" : (weight.to_f / (height.to_f / 100)**2).round(1)
  end

  def target
    batch.target.to_f
  end

  def add_delta_to_target(batch_target)
    @delta_to_target = compute_delta_to_target(batch_target)
  end

  def compute_delta_to_target(batch_target)
    # When querying all entries of all batches, batch_target is set to nil
    # This implies querying the batch target for each entries,
    # which leads to as many queries as there are entries - TO FIX
    if batch_target.nil?
      return -(target - weight.to_f).round(1) unless target == 0.0
      "/"

    # Querying all entries for a specific batch
    else
      return -(batch_target - weight.to_f).round(1) unless batch_target == 0.0
      "/"
    end
  end
end
