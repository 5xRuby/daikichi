# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_time do
    year { 2016 }

    factory :annual_leave_time do
      leave_type { "annual" }
    end

    factory :sick_leave_time do
      leave_type { "sick" }
    end

    factory :personal_leave_time do
      leave_type { "personal" }
    end

    factory :bonus_leave_time do
      leave_type { "bonus" }
    end
  end
end
