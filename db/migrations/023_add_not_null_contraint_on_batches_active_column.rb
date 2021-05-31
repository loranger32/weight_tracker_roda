Sequel.migration do
  up do
    alter_table(:batches) { set_column_not_null :active }
  end

  down do
    alter_table(:batches) { set_column_allow_null :active }
  end
end
