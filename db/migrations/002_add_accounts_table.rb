# Extracted from Rodauth README

Sequel.migration do
  up do
    extension :date_arithmetic

    # Used by the account verification and close account features
    create_table(:account_statuses) do
      Integer :id, :primary_key=>true
      String :name, :null=>false, :unique=>true
    end
    from(:account_statuses).import([:id, :name], [[1, 'Unverified'], [2, 'Verified'], [3, 'Closed']])

    db = self
    create_table(:accounts) do
      primary_key :id, :type=>:Bignum
      foreign_key :status_id, :account_statuses, :null=>false, :default=>1
      citext :email, :null=>false
      constraint :valid_email, :email=>/^[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+$/
      index :email, :unique=>true, :where=>{:status_id=>[1, 2]}
      String :password_hash, :null=>false
    end

    deadline_opts = proc do |days|
      {:null=>false, :default=>Sequel.date_add(Sequel::CURRENT_TIMESTAMP, :days=>days)}
    end

    # Used by the audit logging feature
    json_type = :jsonb

    create_table(:account_authentication_audit_logs) do
      primary_key :id, :type=>:Bignum
      foreign_key :account_id, :accounts, :null=>false, :type=>:Bignum
      DateTime :at, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
      String :message, :null=>false
      column :metadata, json_type
      index [:account_id, :at], :name=>:audit_account_at_idx
      index :at, :name=>:audit_at_idx
    end

    # Used by the password reset feature
    create_table(:account_password_reset_keys) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :key, :null=>false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
    end

    # Used by the account verification feature
    create_table(:account_verification_keys) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :key, :null=>false
      DateTime :requested_at, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
      DateTime :email_last_sent, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
    end

    # Used by the verify login change feature
    create_table(:account_login_change_keys) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :key, :null=>false
      String :login, :null=>false
      DateTime :deadline, deadline_opts[1]
    end

    # Used by the remember me feature
    create_table(:account_remember_keys) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :key, :null=>false
      DateTime :deadline, deadline_opts[14]
    end

    # Used by the lockout feature
    create_table(:account_login_failures) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      Integer :number, :null=>false, :default=>1
    end
    create_table(:account_lockouts) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :key, :null=>false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent
    end

    # Used by the email auth feature
    create_table(:account_email_auth_keys) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :key, :null=>false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
    end


    # Used by the single session feature
    create_table(:account_session_keys) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :key, :null=>false
    end

    # Used by the active sessions feature
    create_table(:account_active_session_keys) do
      foreign_key :account_id, :accounts, :type=>:Bignum
      String :session_id
      Time :created_at, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
      Time :last_use, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
      primary_key [:account_id, :session_id]
    end

    # Used by the webauthn feature
    create_table(:account_webauthn_user_ids) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :webauthn_id, :null=>false
    end

    create_table(:account_webauthn_keys) do
      foreign_key :account_id, :accounts, :type=>:Bignum
      String :webauthn_id
      String :public_key, :null=>false
      Integer :sign_count, :null=>false
      Time :last_use, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
      primary_key [:account_id, :webauthn_id]
    end

    # Used by the otp feature
    create_table(:account_otp_keys) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :key, :null=>false
      Integer :num_failures, :null=>false, :default=>0
      Time :last_use, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
    end

    # Used by the recovery codes feature
    create_table(:account_recovery_codes) do
      foreign_key :id, :accounts, :type=>:Bignum
      String :code
      primary_key [:id, :code]
    end

    # Used by the sms codes feature
    create_table(:account_sms_codes) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :phone_number, :null=>false
      Integer :num_failures
      String :code
      DateTime :code_issued_at, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:account_sms_codes,
               :account_recovery_codes,
               :account_otp_keys,
               :account_webauthn_keys,
               :account_webauthn_user_ids,
               :account_session_keys,
               :account_active_session_keys,
               :account_email_auth_keys,
               :account_lockouts,
               :account_login_failures,
               :account_remember_keys,
               :account_login_change_keys,
               :account_verification_keys,
               :account_password_reset_keys,
               :account_authentication_audit_logs,
               :accounts,
               :account_statuses)
  end
end
