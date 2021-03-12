class Entry < Sequel::Model
  attr_accessor :delta

  def self.all_desc
    order(:day).reverse.all
  end

  def self.most_recent_weight
    all_desc.first.weight.to_f
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
