# Requirements

* Ruby 2.3.1
* Rails 5
* Postgresql 9.4.4

# Installation

```
$ git clone git@github.com:jodeci/daikichi.git  
$ cd daikichi
  
# generate key with rake secret
$ cp config/secrets.yml.sample config/secrets.yml  

# default admin user data
$ cp config/application.yml.sample config/application.yml  

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