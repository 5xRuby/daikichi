# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_application do
    user
    leave_type  'personal'
    description { Faker::Lorem.characters(30) }
    start_time  { Daikichi::Config::Biz.periods.after(Time.current.beginning_of_day).first.start_time }
    end_time    { Daikichi::Config::Biz.periods.after(Time.current.beginning_of_day).first(2).second.end_time }

    trait :sick do
      leave_type 'sick'
    end

    trait :personal do
      leave_type 'personal'
    end

    trait :bonus do
      leave_type 'bonus'
    end

    trait :annual do
      leave_type 'annual'
    end

    trait :pending do
      status 'pending'
    end

    trait :approved do
      before(:create) do |la|
        create(:leave_time, la.leave_type.to_sym, user: la.user, quota: 56, usable_hours: 56,
                                                  effective_date:  la.start_time - 50.days,
                                                  expiration_date: la.start_time + 1.year)
      end

      after(:create) do |la|
        la.reload.approve! create(:user, [:manager, :hr].sample)
      end
    end

    trait :rejected do
      status 'rejected'
      association :manager, factory: [:user, :manager]
    end

    trait :canceled do
      status 'canceled'
    end

    trait :happened do
      start_time { 1.minute.ago.beginning_of_hour }
      end_time   { 1.day.since.beginning_of_hour }
    end

    trait :next_year do
      start_time { Daikichi::Config::Biz.periods.after(1.year.since).first.start_time }
      end_time   { Daikichi::Config::Biz.periods.after(1.year.since).first(2).second.end_time }
    end

    trait :with_leave_time do
      before(:create) do |la|
        create(:leave_time, la.leave_type.to_sym, user: la.user, quota: 56, usable_hours: 56,
                                                  effective_date:  la.start_time - 50.days,
                                                  expiration_date: la.start_time + 1.year)
      end
      after(:stub) do |la|
        create(:leave_time, la.leave_type.to_sym, user: la.user, quota: 56, usable_hours: 56,
                                                  effective_date:  la.start_time - 50.days,
                                                  expiration_date: la.start_time + 1.year)
      end
    end
  end
end
