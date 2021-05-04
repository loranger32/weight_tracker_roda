Sequel.migration do
  up do
    create_table(:batches) do
      primary_key :id
      foreign_key :account_id
      TrueClass :active
    end

    alter_table(:entries) do
      add_foreign_key :batch_id, :batches, on_delete: :cascade
    end
  end

  down do
    alter_table(:entries) do
      drop_foreign_key :batch_id
    end

    drop_table(:batches)
  end
end
