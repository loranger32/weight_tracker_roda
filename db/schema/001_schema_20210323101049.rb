Sequel.migration do
  change do
    create_table(:account_statuses) do
      column :id, "integer", :null=>false
      column :name, "text", :null=>false
      
      primary_key [:id]
      
      index [:name], :name=>:account_statuses_name_key, :unique=>true
    end
    
    create_table(:schema_info) do
      column :version, "integer", :default=>0, :null=>false
    end
    
    create_table(:accounts) do
      primary_key :id, :type=>:Bignum
      foreign_key :status_id, :account_statuses, :default=>1, :null=>false, :key=>[:id]
      column :email, "citext", :null=>false
      column :password_hash, "text", :null=>false
      column :user_name, "text", :null=>false
    end
    
    create_table(:account_active_session_keys) do
      foreign_key :account_id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :session_id, "text", :null=>false
      column :created_at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      column :last_use, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:account_id, :session_id]
    end
    
    create_table(:account_authentication_audit_logs) do
      primary_key :id, :type=>:Bignum
      foreign_key :account_id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      column :message, "text", :null=>false
      column :metadata, "jsonb"
      
      index [:account_id, :at], :name=>:audit_account_at_idx
      index [:at], :name=>:audit_at_idx
    end
    
    create_table(:account_email_auth_keys) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :key, "text", :null=>false
      column :deadline, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      column :email_last_sent, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_lockouts) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :key, "text", :null=>false
      column :deadline, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      column :email_last_sent, "timestamp without time zone"
      
      primary_key [:id]
    end
    
    create_table(:account_login_change_keys) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :key, "text", :null=>false
      column :login, "text", :null=>false
      column :deadline, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_login_failures) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :number, "integer", :default=>1, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_otp_keys) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :key, "text", :null=>false
      column :num_failures, "integer", :default=>0, :null=>false
      column :last_use, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_password_reset_keys) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :key, "text", :null=>false
      column :deadline, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      column :email_last_sent, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_recovery_codes) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :code, "text", :null=>false
      
      primary_key [:id, :code]
    end
    
    create_table(:account_remember_keys) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :key, "text", :null=>false
      column :deadline, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_session_keys) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :key, "text", :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_sms_codes) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :phone_number, "text", :null=>false
      column :num_failures, "integer"
      column :code, "text"
      column :code_issued_at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_verification_keys) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :key, "text", :null=>false
      column :requested_at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      column :email_last_sent, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:account_webauthn_keys) do
      foreign_key :account_id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :webauthn_id, "text", :null=>false
      column :public_key, "text", :null=>false
      column :sign_count, "integer", :null=>false
      column :last_use, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      primary_key [:account_id, :webauthn_id]
    end
    
    create_table(:account_webauthn_user_ids) do
      foreign_key :id, :accounts, :type=>"bigint", :null=>false, :key=>[:id]
      column :webauthn_id, "text", :null=>false
      
      primary_key [:id]
    end
    
    create_table(:entries) do
      primary_key :id
      column :day, "date", :null=>false
      column :weight, "numeric(3,1)", :null=>false
      column :note, "text"
      foreign_key :account_id, :accounts, :null=>false, :key=>[:id]
      
      index [:account_id, :day], :name=>:entries_day_account_id_ukey, :unique=>true
    end
  end
end
