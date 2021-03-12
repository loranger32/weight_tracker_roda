Sequel.migration do
  change do
    create_table :entries do
      primary_key :id
      Date :day, null: false, unique: true
      Numeric :weight, size: [3, 1], null: false
      String :note
    end
  end
end
