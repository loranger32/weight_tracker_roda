Sequel.migration do
  up do
    alter_table(:entries) do
      add_unique_constraint [:account_id, :day], name: :entries_day_account_id_ukey
    end
  end

  down do
    alter_table(:entries) do
      drop_constraint(:entries_day_account_id_ukey)
    end
  end
end
