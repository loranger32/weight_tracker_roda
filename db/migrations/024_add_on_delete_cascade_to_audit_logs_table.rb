Sequel.migration do
  up do
    alter_table(:account_authentication_audit_logs) do
      drop_foreign_key([:account_id], name: "account_authentication_audit_logs_account_id_fkey")
      add_foreign_key([:account_id], :accounts, on_delete: :cascade, name: "account_authentication_audit_logs_account_id_cascade_fkey")
    end
  end

  down do       
    alter_table(:account_authentication_audit_logs) do
      drop_foreign_key([:account_id], name: "account_authentication_audit_logs_account_id_cascade_fkey")
      add_foreign_key([:account_id], :accounts, name: "account_authentication_audit_logs_account_id_fkey")
    end
  end
end
