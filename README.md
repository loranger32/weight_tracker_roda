# README

## Weight Tracker (0.14.0)

A simple app to track your daily weight, with charts.

The goal is to allow for easy daily recording, and to see your progress on (hopefully) nice and useful charts.

Developed with [Roda](http://roda.jeremyevans.net/index.html),
[Sequel](http://sequel.jeremyevans.net/), [PostgreSQL](https://www.postgresql.org/),
[Rodauth](http://rodauth.jeremyevans.net/),[Bootstrap](https://getbootstrap.com/) and [Chart.js](https://www.chartjs.org/).

It's fully functional but could be updated in the future, [see next features](#next-features) and [known bugs](#known-bugs).

You can [review the code here](https://github.com/loranger32/weight_tracker_roda).


## Currently supported features

### Weight Tracking

- One entry per user and per day
- An entry _must_ have a date and a weight
- An entry _can_ have an associated note
- An entry _can_ have an associated alcohol consumption info
- An entry _can_ have an associated sport activity info
- Every entry is linked to one (and only one) batch, to allow you to group entries by specific time periods
- Each batch _can_ have an associated **target weight**
- Each entry has a **delta to target** attribute to show the remaining weight to loose / gain before reaching target
- Each entry has the **delta with the last entry**
- If you enter your height on the account page, each entry has a **body mass index** indicator (bmi)
- Entries are by default assigned to the currently active batch, which is the more current scenario. If you want to record it into another batch, you must make it active first (on the batches page)
- There can only be one active batch at a time
- If you delete a batch, all related entries are permanently destroyed
- Entries and batch info's can be downloaded in JSON format on the Account -> Export page


### Authentication (Rodauth features)

- Create Account
- Verify Account
- Verify Account Grace Period
- Close Account
- Login
- Logout
- Change Login
- Verify Login Change
- Reset Password
- Change Password
- Change Password Notify
- Active Sessions
- Audit Logging
- Lockout
- OTP
- Recovery Codes

### Admin features

- Admin can see a list of all accounts, with the following information's for each account :
  - user name
  - email
  - account status (unverified, verified, closed)
  - 2 factor authentication enabled ?
  - is an admin user ?
  - total number of batches
  - total number of entries
  - date of the last entry
- admin can perform the following actions on accounts (except on admin accounts):
  - verify an account
  - close an account
  - open an account (if closed)
  - delete an account
- admin accounts can only be handled at the database level
- _closing_ an account simply makes it unavailable (no login possible), but does not delete any data
- _deleting_ an account permanently deletes all associated data
- from the web app, an admin user has NO ACCESS to individual entries and cannot see weight, notes and batch target weight. But see important note in the "Encryption" title hereafter.


### Encryption

The following data are encrypted before being saved in the database :

- Entries
   - weight
   - note
   - alcohol consumption
   - sport
- batches
  - target weight
- Mensuration
  - height

So even if someone gains an unauthorized access to the database, all these data will be gibberish.

Note that the developer must know the encryption/decryption key and can thus technically decrypt the data, so you'll have to trust him.


## Next Features

- Decide for each batch if you want to loose or gain weight

## Known Bugs

- For an unknown reason (at the moment), if you signup with a "Hotmail" email address, you won't receive the "confirm your email" email OR you will receive it hours later. Things seems to be OK with an outlook.com email address. I still don't know if it's a Hotmail issue, a Sendgrid (configuration) issue or an issue in my own code.


## Installation

- Install latest stable ruby version (use a version manager like [rbenv](https://github.com/rbenv/rbenv), [rvm](https://rvm.io/) or [asdf](https://github.com/asdf-vm/asdf-ruby)).
- Install PostgreSQL and create a database (and a test database if you want to run the tests).
- Clone or download the repository.
- `cd` into it.
- run `bundle install`.
- The app assumes the following environment variable are set (do not put them under version control):
  - DATABASE_URL ==> The connection info to your PostgreSQL database (same variable name for development and production)
  - TEST_DATABASE_URL ==> Connection info to your test database, if you want to run the tests
  - SESSION_SECRET ==> must be a string of at least 64 bytes and should be randomly generated. More info in the [Roda::RodaPlugins::Session documentation](http://roda.jeremyevans.net/rdoc/classes/Roda/RodaPlugins/Sessions.html)
  - SEQUEL_COLUMN_ENCRYPTION_KEY ==> Key to encrypt/decrypt the data before being saved into the database. [More information here](http://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/ColumnEncryption.html).
  - MY_EMAIL ==> The email address where admin notifications will be sent in production mode
  - SENDRGID_API_KEY ==> to allow sending email in production mode (not needed in development and tests). Obviously requires a Sendgrid account.
- Run `rake db:migrate` to create the database tables (if the `TEST_DATABASE_URL` environment variable is set, it will also create the test database).
- _(optional)_ run `rake db:seed` to insert the seed data.
- _(optional)_ run `rake` to run the test to confirm that everything works as expected.
- In development mode, you can use the [mailcatcher gem](https://rubygems.org/gems/mailcatcher) in order to send email to a local SMTP server
- For a development server _with_ auto reloading feature, run `rake ds`
- For a development server _without_ reloading feature, run `rake s`
- For a production server, run `rake ps`
- For a list of all rake tasks, run `rake -T`

## Contribution

See a bug or something you want to improve ? Great :
- Fork the repository ;
- Create your own branch (git checkout -b my-new-feature) ;
- Make your feature addition or bug fix ;
- Add tests for it (important);
- Commit on your own branch ;
- Push to the branch (git push origin my-new-feature) ;
- Create a new pull request ;

Or simply open an issue on GitHub.

## License

MIT
