# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_hours_by_date do
    leave_application
    date { Date.current }
    hours 1
  end
end
