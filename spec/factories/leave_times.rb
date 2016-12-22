# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_time do
    user
    year { Time.current.year }
    leave_type "annual"

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
