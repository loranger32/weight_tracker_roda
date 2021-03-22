require 'sequel'
require 'bcrypt'

DB = Sequel.connect(ENV['DATABASE_URL'])

accounts = [ { email: 'bob@example.com',
               user_name: 'Bob',
               password_hash: BCrypt::Password.create("helloworld", cost: 2) },
             { email: 'alice@example.com',
               user_name: 'Alice',
               password_hash: BCrypt::Password.create("supersecret", cost: 2) },
             { email: ENV['MY_EMAIL'],
               user_name: 'Laurent',
               password_hash: BCrypt::Password.create("foobar", cost: 2) } ]

accounts.each { |account| DB[:accounts].insert(account) }

entries = [ { weight: 85.0, day: "2021-01-01", note: 'First day' },
            { weight: 84.0, day: "2021-01-02", note: '' },
            { weight: 83.5, day: "2021-01-03", note: 'Great !' },
            { weight: 83.2, day: "2021-01-04", note: 'Keep going' },
            { weight: 84.0, day: "2021-01-05", note: "Don't give up"} ]

entries.each { |entry| DB[:entries].insert(entry) }
