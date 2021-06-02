Sequel.migration do
  up do
    alter_table(:entries) do
      set_column_not_null :weight
      c = Sequel[:weight]
      add_constraint(:weight_format, c.like("AA__A%") | c.like("Ag__A%") | c.like("AQ__A%"))
      add_constraint(:encrypted_weight_length, Sequel.char_length(c) >= 88)
      add_constraint(:enc_base64_weight) do
        octet_length(decode(regexp_replace(regexp_replace(c, "_", "/", "g"), "-", "+", "g"), "base64")) >= 65
      end
    end
  end

  down do
    alter_table(:entries) do
      set_column_allow_null :weight
      drop_constraint(:weight_format)
      drop_constraint(:encrypted_weight_length)
      drop_constraint(:enc_base64_weight)
    end
  end
end
