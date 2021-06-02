Sequel.migration do
  change do
    alter_table(:entries) do
      c = Sequel[:note]
      add_constraint(:note_format, c.like("AA__A%") | c.like("Ag__A%") | c.like("AQ__A%"))
      add_constraint(:encrypted_column_name_length, Sequel.char_length(c) >= 88)
      add_constraint(:enc_base64) do
        octet_length(decode(regexp_replace(regexp_replace(c, "_", "/", "g"), "-", "+", "g"), "base64")) >= 65
      end
    end
  end
end
