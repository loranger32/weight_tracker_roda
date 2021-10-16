# README

## Weight Tracker

A simple app to track your daily weight, with charts.

The goal is to allow for easy daily recording, and to see your progess on (hopefully) nice and useful charts.

Developped with [Roda](http://roda.jeremyevans.net/index.html),
[Sequel](http://sequel.jeremyevans.net/), [Postgresql](https://www.postgresql.org/),
[Rodauth](http://rodauth.jeremyevans.net/),[Bootstrap](https://getbootstrap.com/) and [Chart.js](https://www.chartjs.org/).

It's the first time I try to integrate Rodauth, and it's been great so far.

It's still a work in progress, [see next features](#next-features) and [known bugs](#known-bugs).

You can [review the code here](https://github.com/loranger32/weight_tracker_roda).


## Currently supported features

### Weight Tracking

- One entry per user and per day
- An entry _must_ have a date and a weight
- An entry _can_ have an associated note
- Every entry is linked to one batch, to allow you to separte entries into specific time periods
- Each batch _can_ have an associated **target weight**
- Each entry has a **delta to target** attribute to show the remaining weight to loose / gain
- Each entry has the **delta with the last entry**
- Each entry has a **body mass index** indicator (bmi)
- Entries are by default assigned to the currently active batch, but you can choose to assign it to another one
- There can only be one active batch at a time
- If you delete a batch, all related entries are permanently destroyed
- Entries and batch infos can be downloaded in JSON format


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
- Otp
- Recovery Codes

### Admin features

- Admin can see a list of all accounts, with the following information for each account :
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
- _deleting_ an account permantly deletes all associated data
- an admin user has NO ACCESS to individual entries and cannot see weight, notes and batch target weight


### Encryption

The follwoing data are encrypted before being saved in the database :

- Entries
   - weight
   - note
- batches
  - target weight
- Mensuration
  - height

So even if someone gains an unauthorized access to the database, all these data will be gribberisch.

Note that the developer must know the encryption/decryption key and can thus technically decrypt the data, so you'll have to trust him.


## Next Features

- Add useful stats


## Known Bugs

- when naming your batch, only use ASCII character, because you can enconuter some issues in production. Under investigation


## Installation

- Install Ruby 3.0.2
- Install Postresql and create a database (and a test database if you want to run the tests)
- Clone or download the repository
- `cd` into it.
- run `bundle install`
- Run `rake db:migrate` to create the database tables
- _(optionnal)_ run `rake db:seed` to insert the seed data
- The app assumes the following environment variable are set (do not put them under version control):
  - DATABASE_URL ==> The connection info to your postgresql database (same variable name for development and production)
  - TEST_DATABASE_URL ==> Connection for your test database, if you want to run the tests
  - SESSION_SECRET ==> must be a string of at least 64 bytes and should be randomly generated. More info in the [Roda::RodaPlugins::Session documentation](http://roda.jeremyevans.net/rdoc/classes/Roda/RodaPlugins/Sessions.html)
  - SEQUEL_COLUMN_ENCRYPTION_KEY ==> Key to encrypt/decrypt the data before being saved into the database. [More information here](http://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/ColumnEncryption.html).
  - MY_EMAIL ==> Your email adress where admin notifications will be sent in production mode
  - SENDRGID_API_KEY ==> to allow sending email in production mode (not needed in development and tests). Ovbsiously requires a sendgrid account.s
- In development mode, you can use the [mailcatcher gem](https://rubygems.org/gems/mailcatcher) in order to send email to a local SMTP server
- For a development server _with_ auto relaoding feature, run `rake ds`
- For a development server _without_ relaoding feature, run `rake s`
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

Or simply open an issue on Github.

## License

MIT
