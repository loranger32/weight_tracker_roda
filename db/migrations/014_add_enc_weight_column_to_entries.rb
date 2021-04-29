Sequel.migration do
  change do
    alter_table(:entries) do
      add_column :enc_weight, String
    end
  end
end
