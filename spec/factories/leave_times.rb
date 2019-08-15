# frozen_string_literal: true
FactoryBot.define do
  factory :leave_time do
    user
    leave_type { 'annual' }
    effective_date  { Time.current.beginning_of_year }
    expiration_date { Time.current.end_of_year }
    quota           { 50 }
    used_hours      { 0 }
    usable_hours    { 50 }
    locked_hours    { 0 }
    remark          { 'Test string' }

    Settings.leave_times.quota_types.keys.each do |type|
      trait type.to_sym do
        leave_type { type }
      end
    end
  end
end
