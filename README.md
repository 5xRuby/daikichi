[![Build Status](https://travis-ci.org/5xRuby/daikichi.svg?branch=development)](https://travis-ci.org/5xRuby/daikichi) [![Code Climate](https://codeclimate.com/github/5xRuby/daikichi/badges/gpa.svg)](https://codeclimate.com/github/5xRuby/daikichi) [![Test Coverage](https://codeclimate.com/github/5xRuby/daikichi/badges/coverage.svg)](https://codeclimate.com/github/5xRuby/daikichi/coverage)
# Requirements

* Ruby 2.3.1
* Rails 5
* Postgresql 9.4.4

# Installation

```
$ git clone git@github.com:5xruby/daikichi.git  
$ cd daikichi

# generate key with rake secret
$ cp config/secrets.yml.sample config/secrets.yml  

# default admin user data
$ cp config/application.yml.sample config/application.yml  

$ cp config/database.yml.sample config/database.yml

$ bundle install  
$ bundle exec rake db:create  
$ bundle exec rake db:migrate  
```

# Optional

## hirb auto enable
```
$ cp .irbrc.sample .irbrc
```

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

## create default admin user

```
# config/application.yml
rake import_data:default_admin
```

## populate user data (development)

```
# lib/tasks/users.yml
$ rake import_data:users
```

## populate leave time data

```
$ rake leave_time:init
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
