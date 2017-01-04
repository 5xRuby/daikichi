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
      name "eddie"
    end

    # base year is as same as the year of time when the code is running
    factory :first_year_employee, traits: [:employee] do
      join_date { 6.month.ago }
    end

    factory :second_year_employee, traits: [:employee] do
      join_date { 18.month.ago }
    end

    factory :third_year_employee, traits: [:employee] do
      join_date { 30.month.ago }
    end

    factory :employee, traits: [:employee] 
  end
end
