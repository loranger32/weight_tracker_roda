Sequel.migration do
  change do
    alter_table(:entries) do
      add_column :enc_note, String
    end
  end
end
