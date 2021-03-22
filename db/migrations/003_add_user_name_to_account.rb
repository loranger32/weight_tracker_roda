Sequel.migration do
  change do
    alter_table(:accounts) do
      add_column :user_name, String, null: false
      add_constraint(:user_name_length_range, Sequel.function(:char_length, :user_name) => 3..100)
    end
  end
end
