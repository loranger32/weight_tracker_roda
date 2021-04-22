require "rake/testtask"

unless ENV["RACK_ENV"] == "production"
  require "bcrypt"
  require "standard/rake"
  require "dotenv"
  Dotenv.load
end

MIGRATIONS_PATH = File.expand_path("db/migrations", __dir__)
SCHEMA_PATH = File.expand_path("db/schema", __dir__)

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

desc "Run tests"
task default: :test

desc "Generate random base64 string of given bytes length string, 64 by default"
task :random, [:n] do |t, args|
  require "securerandom"
  n = args[:n]
  n ||= 64
  n = n.to_i
  puts "Random string of #{n} bytes length: #{SecureRandom.base64(n)}"
end

desc "Start interactive console"
task :c do |t|
  system "irb -r ./db/db.rb"
end

desc "Start development server"
task :ds do |t|
  exec "RACK_ENV=development rerun --ignore 'test/*' rackup config.ru"
end

desc "Start classic development server"
task :s do |t|
  system "RACK_ENV=development rackup config.ru"
end

desc "start classic server in production mode"
task :ps do
  system "RACK_ENV=production rackup config.ru"
end

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel/core"
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    Sequel.connect(ENV["DATABASE_URL"]) do |db|
      Sequel::Migrator.run(db, MIGRATIONS_PATH, target: version)
    end

    puts "All migrations applied"

    if ENV["TEST_DATABASE_URL"]
      Sequel.connect(ENV["TEST_DATABASE_URL"]) do |db|
        Sequel::Migrator.run(db, MIGRATIONS_PATH, target: version)
        puts "Migrations also applied to test database"
      end
    end
  end

  desc "Revert all app migrations"
  task :reset do |t|
    require "sequel/core"
    Sequel.extension :migration

    Sequel.connect(ENV["DATABASE_URL"]) do |db|
      Sequel::Migrator.run(db, MIGRATIONS_PATH, target: 0)
    end

    puts "All migrations have been reverted"

    if ENV["TEST_DATABASE_URL"]
      Sequel.connect(ENV["TEST_DATABASE_URL"]) do |db|
        Sequel::Migrator.run(db, MIGRATIONS_PATH, target: 0)
        puts "Also on test database"
      end
    end
  end

  desc "Delete all data from database"
  task :clean do
    require "sequel/core"
    tables = [:account_sms_codes,
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
      :entries,
      :accounts,
      :account_statuses]

    Sequel.connect(ENV["DATABASE_URL"]) do |db|
      tables.each do |table|
        db[table].delete
        puts "Table #{table} deleted"
      end
    end
  end

  desc "Reset database, run all migrations and seed the database"
  task fresh: [:clean, :reset, :migrate, :seed]

  desc "Check pending migrations"
  task :pending do |t|
    require "sequel/core"
    Sequel.extension :migration
    Sequel.connect(ENV["DATABASE_URL"]) do |db|
      if Sequel::Migrator.is_current?(db, MIGRATIONS_PATH)
        puts "No pending migration."
      else
        puts "There are pending migrations. Run 'rake db:migrate' to apply them"
      end
    end

    if ENV["TEST_DATABASE_URL"]
      Sequel.connect(ENV["TEST_DATABASE_URL"]) do |db|
        if Sequel::Migrator.is_current?(db, MIGRATIONS_PATH)
          puts "No pending migration on test database."
        else
          puts "There are pending migrations on the test database. Run 'rake db:migrate' to apply them"
        end
      end
    end
  end

  desc "Inject seed data"
  task :seed do |t|
    system "ruby db/seeds/seeds.rb"
    puts "Seed data have been inserted"
  end

  desc "Dump database schema with timestamp"
  task :schema do |t|
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    destination = File.join(SCHEMA_PATH, "001_schema_#{timestamp}.rb")
    system("sequel -D #{ENV["DATABASE_URL"]} > #{destination}")
    puts "Schema dumped to #{destination}"
  end
end

desc "Cleanup the temp files"
task :clean_tmp do
  temp_directory = File.expand_path("tmp", __dir__)
  number_tmp_files = Dir.entries(temp_directory).length
  if number_tmp_files == 2 # "." and ".."
    puts "Temp directory was empty"
  else
    Dir[File.join(temp_directory, "*")].each { |f| FileUtils.remove_entry_secure(f) }
    puts "Temporary Directory cleaned - #{number_tmp_files - 2} removed"
  end
end

desc "Generate a password hash"
task :gen_ph, [:pw] do |pw|
  puts BCrypt::Password.create(pw, cost: 2)
end
