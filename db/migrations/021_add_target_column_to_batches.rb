Sequel.migration do
  change do
    alter_table(:batches) do
      add_column :target, String
    end
  end
end
