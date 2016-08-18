# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  validates :leave_type, :description, presence: true
  validate :hours_should_be_positive_integer
  before_create :deduct_user_hours
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

    event :reject, after: [proc { |manager| sign(manager) }, :return_user_hours] do
      transitions to: :rejected, from: [:pending]
    end

    event :revise, after: :adjust_user_hours do
      transitions to: :pending, from: [:pending, :approved, :rejected]
    end

    event :cancel, after: :return_user_hours do
      transitions to: :canceled, from: [:pending, :approved, :rejected]
    end

  end

  private

  def deduct_user_hours
    leave_time = LeaveTime.personal(user_id, leave_type)
    assign_hours
    leave_time.adjust_used_hours(hours)
  end

  def return_user_hours
    if aasm.from_state != :rejected
      leave_time = LeaveTime.personal(user_id, leave_type)
      leave_time.adjust_used_hours(-hours)
      @return_leave_application_hours = hours
    end
  end

  def adjust_user_hours
    leave_time = LeaveTime.personal(user_id, leave_type)
    assign_hours
    leave_time.adjust_used_hours(hours-hours_was)

    if @return_leave_application_hours
      leave_time.adjust_used_hours(@return_leave_application_hours)
      @return_leave_application_hours = nil
    end

    save!
  end

  def assign_hours
    self.hours = start_time.working_time_until(end_time) / 3600.0
  end

  def hours_should_be_positive_integer
    unless  ((end_time - start_time) / 3600.0) % 1 == 0
      errors.add(:end_time, :not_integer)
    end
    unless end_time > start_time
      errors.add(:start_time, :should_be_earlier)
    end
  end
end
