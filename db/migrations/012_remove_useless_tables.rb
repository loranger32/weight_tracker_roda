Sequel.migration do
  up do
    drop_table :account_webauthn_keys
    drop_table :account_webauthn_user_ids
    drop_table :account_sms_codes
    drop_table :account_remember_keys
  end

  down do
  end
end
