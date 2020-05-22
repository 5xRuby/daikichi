[![Build Status](https://travis-ci.org/5xRuby/daikichi.svg?branch=development)](https://travis-ci.org/5xRuby/daikichi) [![Code Climate](https://codeclimate.com/github/5xRuby/daikichi/badges/gpa.svg)](https://codeclimate.com/github/5xRuby/daikichi) [![Test Coverage](https://codeclimate.com/github/5xRuby/daikichi/badges/coverage.svg)](https://codeclimate.com/github/5xRuby/daikichi/coverage)
# Requirements

* Ruby 2.6.3
* Rails 5.2.3
* Postgresql 9.4.4

# Installation

```
$ git clone git@github.com:5xruby/daikichi.git
$ cd daikichi

# generate key with rake secret
$ cp config/secrets.yml.sample config/secrets.yml

$ cp config/application.yml.sample config/application.yml
$ cp config/database.yml.sample config/database.yml

$ bundle install
$ bundle exec rake db:create
$ bundle exec rake db:migrate
```

# Optional


## pow + byebug

```
# install pow
$ curl get.pow.cx | sh

# http://daikichi.dev
$ gem install powder
$ powder link

# export BYEBUGPORT={port}
$ cp .powenv.sample .powenv
$ bundle exec byebug -R localhost:{port}
```

## populate user data (development)

```
# lib/tasks/users.csv
$ rake import_data:users
```

## populate leave time data

```
$ rake leave_time:init
```

## populate holiday data

```
$ rake holiday:build
```

## customization

```
# config/locales/meta_data.[locale].yml
misc:
  app_title: "your app title"
  company_name: "your company name"
```

## coding style

```
$ gem install rubocop
$ rubocop
```
