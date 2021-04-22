Sequel.migration do
  up do
    alter_table(:entries) do
      drop_column :note
      rename_column :enc_note, :note
    end
  end

  down do
    alter_table(:entries) do
      rename_column :note, :enc_note
      add_column :note, String
    end
  end
end
