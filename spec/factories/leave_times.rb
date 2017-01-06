# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_time do
    user
    leave_type "annual"
    effective_date  { Time.current.beginning_of_year }
    expiration_date { Time.current.end_of_year }

    trait :annual do
      leave_type "annual"
    end

    trait :sick do
      leave_type "sick"
    end

    trait :personal do
      leave_type "personal"
    end

    trait :bonus do
      leave_type "bonus"
    end
  end
end
