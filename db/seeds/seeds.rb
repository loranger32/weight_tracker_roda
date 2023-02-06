require "bcrypt"
require_relative "../db"

def rand_activity
  Entry::ACTIVITY_TYPE.sample
end

tables = [:account_recovery_codes,
  :account_otp_keys,
  :account_session_keys,
  :account_active_session_keys,
  :account_email_auth_keys,
  :account_lockouts,
  :account_login_failures,
  :account_login_change_keys,
  :account_verification_keys,
  :account_password_reset_keys,
  :account_authentication_audit_logs,
  :admins,
  :entries,
  :batches,
  :accounts]

tables.each { DB.reset_primary_key_sequence(_1) }

accounts = [
  {email: "bob@example.com",
   user_name: "Bob",
   password_hash: BCrypt::Password.create("helloworld", cost: 2),
   status_id: 2},
  {email: "alice@example.com",
   user_name: "Alice",
   password_hash: BCrypt::Password.create("supersecret", cost: 2),
   status_id: 2},
  {email: ENV["MY_EMAIL"],
   user_name: "Laurent",
   password_hash: BCrypt::Password.create("foobar", cost: 2),
   status_id: 2},
  {email: "roger@example.com",
   user_name: "Roger",
   password_hash: BCrypt::Password.create("123456", cost: 2),
   status_id: 1},
  {email: "albert@example.com",
   user_name: "Albert",
   password_hash: BCrypt::Password.create("abcdef", cost: 2),
   status_id: 3}
]

accounts.each { |account| Account.new(account).save }

mensurations = [{account_id: 1, height: "192"}, {account_id: 2, height: "175"},
  {account_id: 3, height: "189"}, {account_id: 4, height: "156"},
  {account_id: 5, height: "175"}]

mensurations.each { |mensuration| Mensuration.new(mensuration).save }

Admin.new(account_id: 3).save

batches = [{account_id: 1, active: false, name: "First run", target: "80.0"},
  {account_id: 1, active: true, name: "Batch 2", target: "80.0"},
  {account_id: 5, active: true, name: "Batch 1", target: "76.0"}]

batches.each { |batch| Batch.new(batch).save }

entries = [{weight: "85.0", day: "2021-01-01", alcohol_consumption: rand_activity, sport: rand_activity, note: "First day", account_id: 1, batch_id: 1},
  {weight: "84.0", day: "2021-01-02", alcohol_consumption: rand_activity, sport: rand_activity, note: "", account_id: 1, batch_id: 1},
  {weight: "88.8", day: "2021-01-03", alcohol_consumption: rand_activity, sport: rand_activity, note: "Great !", account_id: 1, batch_id: 2},
  {weight: "87.2", day: "2021-01-04", alcohol_consumption: rand_activity, sport: rand_activity, note: "Keep going", account_id: 1, batch_id: 2},
  {weight: "87.9", day: "2021-01-05", alcohol_consumption: rand_activity, sport: rand_activity, note: "Don't give up", account_id: 1, batch_id: 2},
  {weight: "88.1", day: "2021-01-06", alcohol_consumption: rand_activity, sport: rand_activity, note: "Great !", account_id: 1, batch_id: 2},
  {weight: "87.6", day: "2021-01-07", alcohol_consumption: rand_activity, sport: rand_activity, note: "Keep going", account_id: 1, batch_id: 2},
  {weight: "87.1", day: "2021-01-08", alcohol_consumption: rand_activity, sport: rand_activity, note: "Don't give up", account_id: 1, batch_id: 2},
  {weight: "86.8", day: "2021-01-09", alcohol_consumption: rand_activity, sport: rand_activity, note: "Great !", account_id: 1, batch_id: 2},
  {weight: "86.6", day: "2021-01-10", alcohol_consumption: rand_activity, sport: rand_activity, note: "Keep going", account_id: 1, batch_id: 2},
  {weight: "87.2", day: "2021-01-12", alcohol_consumption: rand_activity, sport: rand_activity, note: "Don't give up", account_id: 1, batch_id: 2},
  {weight: "87.0", day: "2021-01-13", alcohol_consumption: rand_activity, sport: rand_activity, note: "Great !", account_id: 1, batch_id: 2},
  {weight: "86.3", day: "2021-01-14", alcohol_consumption: rand_activity, sport: rand_activity, note: "Keep going", account_id: 1, batch_id: 2},
  {weight: "86.0", day: "2021-01-15", alcohol_consumption: rand_activity, sport: rand_activity, note: "Don't give up", account_id: 1, batch_id: 2},
  {weight: "85.8", day: "2021-01-16", alcohol_consumption: rand_activity, sport: rand_activity, note: "Great !", account_id: 1, batch_id: 2},
  {weight: "86.5", day: "2021-01-17", alcohol_consumption: rand_activity, sport: rand_activity, note: "Keep going", account_id: 1, batch_id: 2},
  {weight: "85.9", day: "2021-01-18", alcohol_consumption: rand_activity, sport: rand_activity, note: "Don't give up", account_id: 1, batch_id: 2},
  {weight: "85.0", day: "2021-01-19", alcohol_consumption: rand_activity, sport: rand_activity, note: "Great !", account_id: 1, batch_id: 2},
  {weight: "84.8", day: "2021-01-20", alcohol_consumption: rand_activity, sport: rand_activity, note: "Keep going", account_id: 1, batch_id: 2},
  {weight: "85.0", day: "2021-01-21", alcohol_consumption: rand_activity, sport: rand_activity, note: "Don't give up", account_id: 1, batch_id: 2},
  {weight: "84.7", day: "2021-01-22", alcohol_consumption: rand_activity, sport: rand_activity, note: "Great !", account_id: 1, batch_id: 2},
  {weight: "84.5", day: "2021-01-23", alcohol_consumption: rand_activity, sport: rand_activity, note: "Keep going", account_id: 1, batch_id: 2},
  {weight: "84.0", day: "2021-01-24", alcohol_consumption: rand_activity, sport: rand_activity, note: "Don't give up", account_id: 1, batch_id: 2},
  {weight: "84.0", day: "2021-01-02", alcohol_consumption: rand_activity, sport: rand_activity, note: "", account_id: 5, batch_id: 3},
  {weight: "83.5", day: "2021-01-03", alcohol_consumption: rand_activity, sport: rand_activity, note: "I stop !", account_id: 5, batch_id: 3}]

entries.each { |entry| Entry.new(entry).save }
