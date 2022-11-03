Sequel.migration do
  change do
    alter_table(:entries) do
      add_column :sport, String
    end
  end
end