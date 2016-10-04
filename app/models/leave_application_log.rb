# frozen_string_literal: true
class LeaveApplicationLog < ApplicationRecord
  belongs_to :leave_application, foreign_key: "leave_application_uuid", primary_key: "uuid"
end
