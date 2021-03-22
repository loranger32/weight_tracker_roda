Sequel.migration do
  change do
    alter_table(:entries) do
      add_foreign_key :account_id, :accounts, foreign_key_constraint_name: :entries_account_id_fkey
    end
  end
end
