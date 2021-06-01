Sequel.migration do
  up do
    alter_table(:entries) do
      drop_foreign_key([:account_id], name: "entries_account_id_fkey")
      add_foreign_key([:account_id], :accounts, null: false, on_delete: :cascade, name: "entries_account_id_cascade_fkey")
    end
  end

  down do
    alter_table(:entries) do
      drop_foreign_key([:account_id], name: "entries_account_id_cascade_fkey")
      add_foreign_key([:account_id], :accounts, null: false, name: "entries_account_id_fkey")
    end
  end
end
