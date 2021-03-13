require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'])

entries = [ { weight: 85.0, day: "2021-01-01", note: 'First day' },
            { weight: 84.0, day: "2021-01-02", note: '' },
            { weight: 83.5, day: "2021-01-03", note: 'Great !' },
            { weight: 83.2, day: "2021-01-04", note: 'Keep going' } ]

entries.each { |entry| DB[:entries].insert(entry) }


