Sequel.migration do
  up do
    drop_table :account_webauthn_keys
    drop_table :account_webauthn_user_ids
    drop_table :account_sms_codes
    drop_table :account_remember_keys
  end

  down do
    extension :date_arithmetic

    deadline_opts = proc do |days|
      {null: false, default: Sequel.date_add(Sequel::CURRENT_TIMESTAMP, days: days)}
    end
    
    # Used by the webauthn feature
    create_table(:account_webauthn_user_ids) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :webauthn_id, null: false
    end

    create_table(:account_webauthn_keys) do
      foreign_key :account_id, :accounts, type: :Bignum
      String :webauthn_id
      String :public_key, null: false
      Integer :sign_count, null: false
      Time :last_use, null: false, default: Sequel::CURRENT_TIMESTAMP
      primary_key [:account_id, :webauthn_id]
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
