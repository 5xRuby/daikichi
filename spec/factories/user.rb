# frozen_string_literal: true
FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    login_name { Faker::Internet.user_name }
    email { Faker::Internet.safe_email }
    password { Faker::Internet.password }
  end

  trait :admin do
    role { "admin" }
  end

  trait :manager do
    role { "manager" }
  end

  trait :employee do
    role { "employee" }
  end

  trait :contractor do
    role { "contractor" }
    join_date { nil }
  end

  trait :freshman do
    role { "employee" }
    join_date { Faker::Date.between(Date.new(Time.zone.today.year, 1, 1), Time.zone.today) }
  end

  trait :senior do
    role { "employee" }
    join_date { Faker::Date.between(35.years.ago, 1.year.ago) }
  end
end
