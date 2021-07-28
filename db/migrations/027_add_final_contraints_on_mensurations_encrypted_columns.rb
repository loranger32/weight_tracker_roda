Sequel.migration do
  up do
    alter_table(:mensurations) do
      c = Sequel[:height]
      add_constraint(:height_format, c.like("AA__A%") | c.like("Ag__A%") | c.like("AQ__A%"))
      add_constraint(:encrypted_height_length, Sequel.char_length(c) >= 88)
      add_constraint(:enc_base64_height) do
        octet_length(decode(regexp_replace(regexp_replace(c, "_", "/", "g"), "-", "+", "g"), "base64")) >= 65
      end
    end
  end

  down do
    alter_table(:mensurations) do
      drop_constraint(:height_format)
      drop_constraint(:encrypted_height_length)
      drop_constraint(:enc_base64_height)
    end
  end
end
