Sequel.migration do
  change do
    alter_table(:mensurations) do
      add_index :account_id, unique: true
    end
  end
end
