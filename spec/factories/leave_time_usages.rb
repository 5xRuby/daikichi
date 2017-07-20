# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_time_usage do
    leave_application nil
    leave_time nil
    used_hours 1
  end
end
