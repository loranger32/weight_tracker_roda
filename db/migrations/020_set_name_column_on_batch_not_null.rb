Sequel.migration do
  up do
    alter_table(:batches) do
      set_column_not_null :name
    end
  end

  down do
    alter_table(:batches) do
      set_column_allow_null :name
    end
  end
end
