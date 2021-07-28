Sequel.migration do
  change do
    alter_table(:admins) do
      add_index :account_id, unique: true
    end
  end
end
