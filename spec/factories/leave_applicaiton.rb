# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_application do
    user
    leave_type  "personal"
    description { Faker::Lorem.characters(30) }
    start_time  { 3.working.day.from_now.beginning_of_day + 9.hours + 30.minutes }
    end_time    { 5.working.day.from_now.beginning_of_day + 18.hours + 30.minutes }

    trait :sick do
      leave_type "sick"
    end

    trait :personal do
      leave_type "personal"
    end

    trait :bonus do
      leave_type "bonus"
    end

    trait :annual do
      leave_type "annual"
    end

    trait :approved do
      status 'approved'
      association :manager, factory: [:user, :manager]
    end

    trait :happened do
      start_time { 1.minutes.ago.beginning_of_hour }
      end_time   { 1.days.since.beginning_of_hour }
    end

    trait :next_year do
      start_time { WorkingHours.next_working_time(1.year.since) }
      end_time   { WorkingHours.next_working_time(1.year.since) + 9.hours }
    end

    trait :with_leave_time do
      before(:create) do |la|
        create(:leave_time, la.leave_type.to_sym, user: la.user, quota: 56, usable_hours: 56, year: la.start_time.year)
      end
      after(:stub) do |la|
        create(:leave_time, la.leave_type.to_sym, user: la.user, quota: 56, usable_hours: 56, year: la.start_time.year)
      end
    end
  end
end
