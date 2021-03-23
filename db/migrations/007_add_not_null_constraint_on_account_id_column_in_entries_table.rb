Sequel.migration do
  up do
    alter_table(:entries) do
      set_column_not_null :account_id
    end
  end

  down do
    alter_tabme(:entries) do
      set_column_allow_null :account_id
    end
  end
end
