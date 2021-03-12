require 'rake/testtask'

require 'dotenv'
Dotenv.load

MIGRATIONS_PATH = File.expand_path('db/migrations', __dir__)
SCHEMA_PATH = File.expand_path('db/schema', __dir__)

Rake::TestTask.new do |t|
  t.pattern = 'test/*_test.rb'
  t.warning = false
end

desc "Run tests"
task :default => :test

desc "Generate random base64 64 length string (for sessions secret)"
task :random do
  require "securerandom"
  secret = SecureRandom.base64(64)
  puts secret
end

desc 'Start interactive console'
task :c do |t|
  system "irb -r ./db/db.rb"
end

desc "Start development server"
task :ds do |t|
  exec "RACK_ENV=development rerun --ignore 'test/*' rackup config.ru "
end

desc 'Start classic development server'
task :s do |t|
  system "RACK_ENV=development rackup config.ru"
end

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel/core"
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    Sequel.connect(ENV['DATABASE_URL']) do |db|
      Sequel::Migrator.run(db, MIGRATIONS_PATH, target: version)
    end

    puts "All migrations applied"

    if ENV['TEST_DATABASE_URL']
      Sequel.connect(ENV['TEST_DATABASE_URL']) do |db|
        Sequel::Migrator.run(db, MIGRATIONS_PATH, target: version)
        puts "Migrations also applied to test database"
      end
    end
  end

  desc "Revert all app migrations"
  task :reset do |t|
    require "sequel/core"
    Sequel.extension :migration

    Sequel.connect(ENV['DATABASE_URL']) do |db|
      Sequel::Migrator.run(db, MIGRATIONS_PATH, target: 0)
    end

    puts "All migrations have been reverted"

    if ENV['TEST_DATABASE_URL']
      Sequel.connect(ENV['TEST_DATABASE_URL']) do |db|
        Sequel::Migrator.run(db, MIGRATIONS_PATH, target: 0)
        puts "Also on test database"
      end
    end
  end

  desc "Reset database, run all migrations and seed the database"
  task fresh: [:reset, :migrate]

  desc "Check pending migrations"
  task :pending do |t|
    require "sequel/core"
    Sequel.extension :migration
    Sequel.connect(ENV['DATABASE_URL']) do |db|
      if Sequel::Migrator.is_current?(db, MIGRATIONS_PATH)
        puts "No pending migration."
      else
        puts "There are pending migrations. Run 'rake db:migrate' to apply them"
      end
    end

    if ENV['TEST_DATABASE_URL']
      Sequel.connect(ENV['TEST_DATABASE_URL']) do |db|
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
    system("sequel -D #{ENV['DATABASE_URL']} > #{destination}")
    puts "Schema dumped to #{destination}"
  end
end
