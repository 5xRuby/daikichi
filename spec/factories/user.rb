# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    login_name { Faker::Internet.user_name }
    email { Faker::Internet.safe_email }
    password { Faker::Internet.password }
    join_date { Time.zone.today }
    role { 'employee' }

    trait :fulltime do
      role { %i(manager hr employee).sample }
    end

    trait :manager do
      role { 'manager' }
    end

    trait :hr do
      role { 'hr' }
    end

    trait :employee do
      role { 'employee' }
    end

    trait :parttime do
      role { %i(contractor intern).sample }
    end

    trait :intern do
      role { 'intern' }
    end

    trait :contractor do
      role { 'contractor' }
    end

    trait :pending do
      role { 'pending' }
    end

    trait :resigned do
      role { 'resigned' }
      # before(:create) { User.skip_callback(:create, :after, :auto_assign_leave_time) }
      # after(:create)  { User.set_callback(:create, :after, :auto_assign_leave_time)  }
    end

    trait :without_assign_date do
      before(:create) { |user| user.assign_leave_time = '0' }
    end

    factory :manager_eddie, traits: [:manager] do
      name { 'eddie' }
    end

    # base year is as same as the year of time when the code is running
    factory :first_year_employee, traits: [:employee] do
      join_date { 6.months.ago }
    end

    factory :second_year_employee, traits: [:employee] do
      join_date { 18.months.ago }
    end

    factory :third_year_employee, traits: [:employee] do
      join_date { 30.months.ago }
    end

    factory :employee, traits: [:employee]

    before(:create) do |user|
      user.assign_leave_time = '1'
      user.assign_date = user.join_date.to_s
    end
  end
end
