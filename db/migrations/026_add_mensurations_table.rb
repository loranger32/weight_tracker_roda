Sequel.migration do
  change do
    create_table(:mensurations) do
      primary_key :id, type: :Bignum
      foreign_key :account_id, :accounts, null: false, on_delete: :cascade
      String :height, null: false
    end
  end
end
