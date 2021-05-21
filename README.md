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
- Every entry has the delta with the last entry
- Every entry is linked to one batch, to deal with when you stop recording your weight for a long period (one batch per period)
- Entries are automatically assigned to the currently active batch
- There can only be one active batch at a time
- If you delete a batch, all related entries are permanently destroyed


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


### Encryption

Weight and notes attributes are encrypted before being saved in the database and are not searchable.


### Admin function

Admin role is available, but can only see a summary of the account status, and don't have access to the data of the users.


## Next Features

- Currently the front end is quite ugly. I'm still thinking about the right way to handle it.
Options considered are Tailwind.css, Bootstrap 5, Bulma or homemade CSS.

- After that will come the time to add fancy and useful charts ! Probably whit Chart.js
