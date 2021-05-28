Sequel.migration do
  up do
    alter_table(:batches) do
      set_column_not_null :target
      c = Sequel[:target]
      add_constraint(:target_format, c.like('AA__A%') | c.like('Ag__A%') | c.like('AQ__A%'))
      add_constraint(:encrypted_target_length, Sequel.char_length(c) >= 88)
      add_constraint(:enc_base64_target) do
        octet_length(decode(regexp_replace(regexp_replace(c, '_', '/', 'g'), '-', '+', 'g'), 'base64')) >= 65
      end
    end
  end

  down do
    alter_table(:batches) do
      set_column_allow_null :target
      drop_constraint(:target_format)
      drop_constraint(:encrypted_target_length)
      drop_constraint(:enc_base64_target)
    end
  end
end
