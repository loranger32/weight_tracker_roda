Sequel.migration do
  up do
    alter_table(:entries) { set_column_not_null :batch_id }
    alter_table(:batches) { set_column_not_null :account_id }
  end

  down do
    alter_table(:entries) { set_column_allow_null :batch_id }
    alter_table(:batches) { set_column_allow_null :account_id }
  end
end
