class Entry < Sequel::Model
  plugin :validation_helpers
  plugin :json_serializer
  plugin :column_encryption do |enc|
    enc.column :note
    enc.column :weight
  end

  many_to_one :account
  many_to_one :batch

  attr_accessor :delta

  dataset_module do
    def all_desc(account_id:, active_batch:)
      if active_batch
        all_active_in_descending_order_by_date(account_id)
      else
        all_in_descending_order_by_date(account_id)
      end
    end

    def all_in_descending_order_by_date(account_id)
      where(account_id: account_id).reverse_order(:day).all
    end

    def all_active_in_descending_order_by_date(account_id)
      active_batch_id = Batch.where(account_id: account_id, active: true).first.id
      where(account_id: account_id, batch_id: active_batch_id).reverse_order(:day).all
    end

    def most_recent_weight(account_id)
      if (most_recent = all_desc(account_id: account_id, active_batch: false).first)
        most_recent.weight.to_f
      end
    end

    def all_with_deltas(account_id:, active_batch:)
      entries = all_desc(account_id: account_id, active_batch: active_batch)

      entries.each_with_index do |entry, index|
        entry.delta = if entries[index + 1]
          (entry.weight.to_f - entries[index + 1].weight.to_f).round(1)
        else
          0
        end
      end
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
end
