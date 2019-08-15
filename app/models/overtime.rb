# frozen_string_literal: true

class Overtime < ApplicationRecord
  include AASM

  belongs_to :user
  validates :description, :start_time, :end_time, presence: true
  validate :hours_should_be_positive_integer
  before_validation :assign_hours
  enum status: Settings.leave_applications.statuses

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, after_commit: :create_leave_time do
      transitions to: :approved, from: :pending
    end

    event :reject do
      transitions to: :rejected, from: %i(pending approved)
    end

    event :revise do
      transitions to: :pending, from: %i(pending approved)
    end

    event :cancel do
      transitions to: :canceled, from: :pending
      transitions to: :canceled, from: :approved, unless: :happened?
    end
  end

  private

  def happened?
    Time.current > self.start_time
  end

  def auto_calculated_minutes
    return @minutes = 0 unless start_time && end_time

    @minutes = Daikichi::Config::Biz.within(start_time, end_time).in_minutes
  end

  def assign_hours
    self.hours = self.send(:auto_calculated_minutes) / 60
  end

  def hours_should_be_positive_integer
    return if self.errors[:start_time].any? or self.errors[:end_time].any?

    errors.add(:end_time, :not_integer) if (@minutes % 60).nonzero? || !self.hours.positive?
    errors.add(:start_time, :should_be_earlier) unless self.end_time > self.start_time
  end

  def create_leave_time
    if Date.today.month > 10
      LeaveTime.create(leave_type: 'bonus', quota: hours, usable_hours: hours, used_hours: 0, locked_hours: 0, user_id: user_id, effective_date: Date.today, expiration_date: Date.today.end_of_year + 3.months, remark: '申請加班補休核准')
    else
      LeaveTime.create(leave_type: 'bonus', quota: hours, usable_hours: hours, used_hours: 0, locked_hours: 0, user_id: user_id, effective_date: Date.today, expiration_date: Date.today.end_of_year, remark: '申請加班補休核准')
    end
  end
end
