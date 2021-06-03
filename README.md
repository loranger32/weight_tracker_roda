# README

## Weight Tracker

A simple app to track your daily weight, with charts.

The goal is to allow for easy daily recording, and to see your progess on nice charts.

Developped with [Roda](http://roda.jeremyevans.net/index.html),
[Sequel](http://sequel.jeremyevans.net/), [Rodauth](http://rodauth.jeremyevans.net/)
and [Postgresql](https://www.postgresql.org/).

It's the first time I try to integrate Rodauth, and it's been great so far.

It's still a work in progress, [see next features](#Next-Features).


## Currently supported features

### Weight Tracking

- One entry per user and per day
- An entry _must_ have a date and a weight
- An entry _can_ have an associated note
- Every entry is linked to one batch, to deal with when you stop recording your weight for a long period (one batch per period)
- Each batch can have an associated target weight
- Each entry has a delta to target attribute to show the remaining wieght to loose / gain
- Every entry has the delta with the last entry
- Entries are automatically assigned to the currently active batch
- There can only be one active batch at a time
- If you delete a batch, all related entries are permanently destroyed
- entries and batch infos can be downloaded in JSON format


### Authentication (Roaudth features)

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
  - 2 FA enabled ?
  - is an admin user ?
  - total number of batches
  - total number of entries
  - date of the last entry
- admin can perform the following actions on accounts (except on admin accounts):
  - verify an account
  - close an account
  - open an account (if closed)
  - delete an account
- admin accounts can only be handled at the data base level
- closing an account simply makes it unavailable (no login possible), but does not delete any data
- deleting an account permantly deletes all associated data
- an admin user has NO ACCESS to entries weight, notes and batch target weight 


### Encryption

Entries weight, entries note and batch target weight are encrypted before being saved in the database and are not searchable.


## Next Features

- Currently the front end is quite ugly. Given that I'm not a css pro, I'll rely on Bootstrap 5.

- After that will come the time to add fancy and useful charts ! Probably whit Chart.js
