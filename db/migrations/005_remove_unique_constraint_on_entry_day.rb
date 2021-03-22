Sequel.migration do
  up do
    alter_table(:entries) do
      drop_constraint(:entries_day_key)
    end
  end

  down do
    alter_table(:entries) do
      add_unique_constraint(:day)
    end
  end
end
