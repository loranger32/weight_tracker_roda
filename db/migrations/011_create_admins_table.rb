Sequel.migration do
  change do
    create_table(:admins) do
      primary_key :id
      foreign_key :account_id, :accounts, foreign_key_constraint_name: :admins_account_id_fkey
    end
  end
end
