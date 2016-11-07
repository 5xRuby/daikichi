# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_application do
    description { Faker::Lorem.characters(30) }

    factory :sick_leave do
      leave_type { "sick" }
    end

    factory :personal_leave do
      leave_type { "personal" }
    end

    factory :bonus_leave do
      leave_type { "bonus" }
    end

    factory :annual_leave do
      leave_type { "annual" }
    end
  end
end
