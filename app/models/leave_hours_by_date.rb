# frozen_string_literal: true
class LeaveHoursByDate < ApplicationRecord
  belongs_to :leave_application

  validates :leave_application, :date, :hours, presence: true
  validates :hours, numericality: { only_integer: true, greater_than: 0 }
  validates :date,  uniqueness: { scope: :leave_application_id }
end
