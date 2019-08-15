# frozen_string_literal: true
class LeaveTime < ApplicationRecord
  delegate :seniority, :name, to: :user

  enum leave_type: Settings.leave_times.quota_types

  belongs_to :user
  has_many   :leave_time_usages
  has_many   :leave_applications, through: :leave_time_usages

  before_validation :set_default_values
  after_create :build_special_leave_time_usages

  validates :leave_type, :effective_date, :expiration_date, :quota, :usable_hours, :used_hours, :locked_hours, :user, presence: true
  validates :quota,        numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :usable_hours, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :used_hours,   numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :locked_hours, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate  :positive_range
  validate  :balanced_hours

  scope :belong_to, ->(user) {
    where(user: user)
  }

  scope :personal, ->(user_id, leave_type, beginning, closing) {
    overlaps(beginning, closing).find_by(user_id: user_id, leave_type: leave_type)
  }

  scope :overlaps, ->(beginning, closing) {
    where(
      '(leave_times.effective_date, leave_times.expiration_date) OVERLAPS (timestamp :beginning, timestamp :closing)',
      beginning: beginning.beginning_of_day, closing: closing.end_of_day
    )
  }

  scope :effective, ->(date = Time.current) {
    overlaps(date.beginning_of_day, date.end_of_day)
  }

  ransacker :effective do |parent|
    Arel.sql("(select (leave_times.effective_date, leave_times.expiration_date) OVERLAPS (timestamp '#{Time.current.beginning_of_day}', timestamp '#{Time.current.end_of_day}'))")
  end

  def deduct(hours)
    self.used_hours += hours
    self.usable_hours = quota - used_hours
    save!
  end

  def cover?(time_format)
    date = time_format.to_date
    (self.effective_date..self.expiration_date).cover? date
  end

  def special_type?
    %w(marriage compassionate official maternity occpational_sick menstrual).include? self.leave_type
  end

  def lock_hours(hours)
    self.usable_hours -= hours
    self.locked_hours += hours
  end

  def lock_hours!(hours)
    self.lock_hours(hours)
    self.save!
  end

  def unlock_hours(hours)
    self.locked_hours -= hours
    self.usable_hours += hours
  end

  def unlock_hours!(hours)
    self.unlock_hours(hours)
    self.save!
  end

  def use_hours(hours)
    self.locked_hours -= hours
    self.used_hours += hours
  end

  def use_hours!(hours)
    self.use_hours(hours)
    self.save!
  end

  def direct_use_hours(hours)
    self.usable_hours -= hours
    self.used_hours += hours
  end

  def direct_use_hours!(hours)
    self.direct_use_hours(hours)
    self.save!
  end

  def unuse_hours(hours)
    self.used_hours -= hours
    self.usable_hours += hours
  end

  def unuse_hours!(hours)
    self.unuse_hours(hours)
    self.save!
  end

  def unuse_and_lock_hours(hours)
    self.used_hours -= hours
    self.locked_hours += hours
  end

  def unuse_and_lock_hours!(hours)
    self.unuse_and_lock_hours(hours)
    self.save!
  end

  private

  def set_default_values
    self.usable_hours ||= self.quota
    self.used_hours   ||= 0
    self.locked_hours ||= 0
  end

  def positive_range
    return if self.errors[:effective_date].any? || self.errors[:expiration_date].any?
    return if expiration_date >= effective_date
    errors.add(:effective_date, :range_should_be_positive)
  end

  def overlaps?
    LeaveTime.overlaps(effective_date, expiration_date)
      .where(user_id: user_id, leave_type: self.leave_type)
      .where.not(id: self.id).any?
  end

  def balanced_hours
    return if errors[:usable_hours].any? or errors[:used_hours].any? or errors[:locked_hours].any?
    errors.add(:quota, :unbalanced_hours) if quota != (usable_hours + used_hours + locked_hours)
  end

  def build_special_leave_time_usages
    return unless self.special_type?
    leave_applications = User.find(self.user_id).leave_applications.where(leave_type: self.leave_type)
    leave_applications.each do |la|
      if la.leave_time_usages.empty? and la.hours <= la.available_leave_times.pluck(:usable_hours).sum
        raise ActiveRecord::Rollback unless LeaveTimeUsageBuilder.new(la).build_leave_time_usages
      end
    end
  end
end
