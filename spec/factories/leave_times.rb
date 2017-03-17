# frozen_string_literal: true
FactoryGirl.define do
  factory :leave_time do
    user
    leave_type 'annual'
    effective_date  { Time.current.beginning_of_year }
    expiration_date { Time.current.end_of_year }
    quota           0
    used_hours      0
    usable_hours    0

    Settings.leave_application_types.keys.each do |type|
      trait type.to_sym do
        leave_type type
      end
    end
  end
end
