Sequel.migration do
  up do
    alter_table(:entries) do
      drop_column :weight
      drop_column :weight_string
      rename_column :enc_weight, :weight
    end
  end

  down do
    alter_table(:entries) do
      rename_column :weight, :enc_weight
      add_column :weight_string, String, size: 5
      add_column :weight, Numeric, size: [3, 1]
    end
  end
end
