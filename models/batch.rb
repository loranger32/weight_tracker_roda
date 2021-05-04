class Batch < Sequel::Model
  one_to_many :entries
  many_to_one :account
end
