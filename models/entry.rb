class Entry < Sequel::Model
  attr_accessor :delta

  def self.all_desc
    reverse_order(:day).all
  end

  def self.most_recent_weight
    if (most_recent = all_desc.first)
      most_recent.weight.to_f
    end
  end

  def self.all_desc_with_deltas
    entries = all_desc
    entries.each_with_index do |entry, index|
      if entries[index + 1]
        entry.delta = (entry.weight - entries[index + 1].weight).to_f
      else
        entry.delta = 0
      end
    end 
  end
end
