# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_application do
    user
    leave_type  "personal"
    description { Faker::Lorem.characters(30) }
    start_time  { 3.days.since.beginning_of_hour }
    end_time    { 5.days.since.beginning_of_hour }

    trait :sick_leave do
      leave_type "sick"
    end

    trait :personal_leave do
      leave_type "personal"
    end

    trait :bonus_leave do
      leave_type "bonus"
    end

    trait :annual_leave do
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

    trait :with_leave_time do
      before(:create) do |la|
        create(:leave_time, la.leave_type.to_sym, user: la.user)
      end
    end
  end
end
