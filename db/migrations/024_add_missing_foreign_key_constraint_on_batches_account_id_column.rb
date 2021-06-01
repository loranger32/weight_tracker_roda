Sequel.migration do
  up do
    alter_table(:batches) do
      add_foreign_key([:account_id], :accounts, null: false, on_delete: :cascade, name: "batches_account_id_fkey")
    end
  end

  down do
    alter_table(:batches) do
      drop_foreign_key([:account_id], name: "batches_account_id_fkey")
    end
  end
end
