Sequel.migration do
  change do
    alter_table(:entries) do
      add_column :weight_string, String, size: 5
    end
  end
end
