Sequel.migration do
  up do
    drop_table :account_webauthn_keys
    drop_table :account_webauthn_user_ids
    drop_table :account_sms_codes
    drop_table :account_remember_keys
  end

  down do
    # Used by the webauthn feature
    create_table(:account_webauthn_user_ids) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :webauthn_id, null: false
    end

    # Used by the webauthn feature
    create_table(:account_webauthn_user_ids) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :webauthn_id, null: false
    end

    # Used by the sms codes feature
    create_table(:account_sms_codes) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :phone_number, null: false
      Integer :num_failures
      String :code
      DateTime :code_issued_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
    
    # Used by the remember me feature
    create_table(:account_remember_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      DateTime :deadline, deadline_opts[14]
    end
  end
end
