Sequel.migration do
  change do
    alter_table(:batches) do
      add_column :name, String, size: 30
    end
  end
end
