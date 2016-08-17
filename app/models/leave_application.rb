# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  before_validation :assign_hours
  validates :leave_type, :description, presence: true
  validate :hours_should_be_integer
  before_save :deduct_user_hours
  acts_as_paranoid

  LEAVE_TYPE = %i(annual bonus personal sick).freeze

  include AASM
  include SignatureConcern

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
    leave_time.deduct_hours(hours_was, hours)
  end

  def assign_hours
    self.hours = start_time.working_time_until(end_time) / 3600.0
  end

  def hours_should_be_integer
    unless ((end_time - start_time) / 3600.0) % 1 == 0
      errors.add(:end_time, :not_integer)
    end
  end
end
