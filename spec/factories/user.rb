# frozen_string_literal: true
FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    login_name { Faker::Internet.user_name }
    email { Faker::Internet.safe_email }
    password { Faker::Internet.password }

    trait :admin do
      role "admin"
    end

    trait :manager do
      role "manager"
    end

    trait :hr do
      role "hr"
    end

    trait :employee do
      role "employee"
    end

    trait :contractor do
      role "contractor"
      join_date { nil }
    end

    factory :manager_eddie, traits: [:manager] do
      id 1
      name "eddie"
    end

    # base year is as same as the year of time when the code is running
    factory :first_year_employee, traits: [:employee] do
      id { 20 }
      join_date { Time.new(Time.now.year, 6, 1) }
    end

    factory :second_year_employee, traits: [:employee] do
      join_date { Time.new(Time.now.year - 1, 4, 15) }
    end

    factory :third_year_employee, traits: [:employee] do
      join_date { Time.new(Time.now.year - 2, 4, 15) }
    end
  end
end
