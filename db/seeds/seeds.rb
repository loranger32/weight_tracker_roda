require "bcrypt"
require_relative "../db"

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

Admin.new(account_id: 3).save

batches = [{account_id: 1, active: false, name: "First run", target: "80.0"},
  {account_id: 1, active: true, name: "Batch 2", target: "80.0"},
  {account_id: 5, active: true, name: "Batch 1", target: "76.0"}]

batches.each { |batch| Batch.new(batch).save }

entries = [{weight: "85.0", day: "2021-01-01", note: "First day", account_id: 1, batch_id: 1},
  {weight: "84.0", day: "2021-01-02", note: "", account_id: 1, batch_id: 1},
  {weight: "83.5", day: "2021-01-03", note: "Great !", account_id: 1, batch_id: 2},
  {weight: "83.2", day: "2021-01-04", note: "Keep going", account_id: 1, batch_id: 2},
  {weight: "84.0", day: "2021-01-05", note: "Don't give up", account_id: 1, batch_id: 2},
  {weight: "84.0", day: "2021-01-02", note: "", account_id: 5, batch_id: 3},
  {weight: "83.5", day: "2021-01-03", note: "I stop !", account_id: 5, batch_id: 3}]

entries.each { |entry| Entry.new(entry).save }
