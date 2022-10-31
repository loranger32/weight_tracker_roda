Sequel.migration do
  change do
    alter_table(:entries) do
      add_column :alcohol_consumption, String
    end
  end
end