# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  before_save :calculate_hours_and_deduct_it_from_leave_time
  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  validates_presence_of :leave_type, :description
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

  def calculate_hours_and_deduct_it_from_leave_time
    leave_time = self.user.leave_times.where("leave_type = ?", self.leave_type).first
    self.hours = calculate_hours
    unless self.hours_was == self.hours
      leave_time.usable_hours += self.hours_was
      leave_time.usable_hours -= self.hours
      leave_time.save!
    end
  end

  def calculate_hours
    ( end_time - start_time ) / 3600.0
  end
end
