# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  before_save :deduct_user_hours
  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  validates_presence_of :leave_type, :description
  validate :validate_hours
  acts_as_paranoid

  LEAVE_TYPE = %i(annual bonus personal sick).freeze

  include AASM
  include SignatureConcern
  include HoursValidationConcern

  aasm column: :status do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, after: proc { |manager| sign(manager) } do
      transitions to: :approved, from: [:pending]
    end

    event :reject, after: proc { |manager| sign(manager) } do
      transitions to: :rejected, from: [:pending]
    end

    event :revise do
      transitions to: :pending, from: [:pending, :rejected]
    end

    event :cancel do
      transitions to: :canceled, from: [:pending, :approved, :rejected]
    end

  end

  private
  # 找該假單的屬於誰的，扣除他該 leave_type 的時數
  def deduct_user_hours
    leave_time = LeaveTime.personal(user_id, leave_type)
    assign_hours
    leave_time.deduct_hours(hours_was, hours)
  end

  def assign_hours
    self.hours = start_time.business_time_until(end_time) / 3600.0
  end
end
