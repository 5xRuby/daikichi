# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  include AASM
  include SignatureConcern

  enum status: {
    pending:  'pending',
    approved: 'approved',
    rejected: 'rejected',
    canceled: 'canceled'
  }

  acts_as_paranoid
  paginates_per 8

  after_initialize :set_primary_id
  before_validation :assign_hours

  belongs_to :user
  belongs_to :manager, class_name: 'User', foreign_key: 'manager_id'
  belongs_to :leave_time
  has_many :leave_time_usages
  has_many :leave_application_logs, foreign_key: 'leave_application_uuid', primary_key: 'uuid', dependent: :destroy

  validates :leave_type, :description, :start_time, :end_time, presence: true

  validate :hours_should_be_positive_integer

  scope :leave_within_range, ->(beginning = WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month), closing = WorkingHours.return_to_working_time(1.month.ago.end_of_month)) {
    where(
      '(leave_applications.start_time, leave_applications.end_time) OVERLAPS (timestamp :beginning, timestamp :closing)',
      beginning: beginning, closing: closing
    )
  }
  scope :with_status, ->(status) { where(status: status) }

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, after: [proc { |manager| sign(manager) }, :bind_and_make_leave_time_exist] do
      transitions to: :approved, from: [:pending]
    end

    event :reject, after: proc { |manager| sign(manager) } do
      transitions to: :rejected, from: [:pending]
    end

    event :revise do
      transitions to: :pending, from: [:pending, :approved, :rejected]
    end

    event :cancel do
      transitions to: :canceled, from: [:pending, :rejected]
      transitions to: :canceled, from: :approved, unless: :happened?
    end
  end

  class << self
    def with_year(year = Time.now.year)
      t = Time.new(year)
      range = (t.beginning_of_year..t.end_of_year)
      leaves_start_time_included = where(start_time: range)
      leaves_end_time_included = where(end_time: range)
      leaves_start_time_included.or(leaves_end_time_included)
    end

    def leave_hours_within(beginning = WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month), closing = WorkingHours.return_to_working_time(1.month.ago.end_of_month))
      self.leave_within_range(beginning, closing).reduce(0) do |result, la|
        if la.range_exceeded?(beginning, closing)
          @valid_range = [la.start_time, beginning].max..[la.end_time, closing].min
          result + @valid_range.min.working_time_until(@valid_range.max) / 3600.0
        else
          result + la.hours
        end
      end
    end
  end

  attr_accessor :import_mode

  def happened?
    Time.current > self.start_time
  end

  def range_exceeded?(beginning = WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month), closing = WorkingHours.return_to_working_time(1.month.ago.end_of_month))
    beginning > self.start_time || closing < self.end_time
  end

  def is_leave_type?(type = :all)
    return true if type.to_sym == :all
    self.leave_type.to_sym == type.to_sym
  end

  private

  def set_primary_id
    self.uuid ||= SecureRandom.uuid
  end

  def assign_hours
    self.hours = auto_calculated_hours if self.hours.nil? or self.hours == 0
  end

  def auto_calculated_hours
    Biz.within(start_time, end_time).in_hours
  end

  def pre_create_leave_time_if_allowed
    leave_time_tmp.save! if leave_time_tmp.present? && leave_time_tmp.new_record? && leave_time_tmp.allow_pre_creation?
  end

  def ensure_leave_time_hours_correct
    if leave_time_id_changed? || hours_changed? || status_changed?
      return_leave_time_usable_hours
      deduct_leave_time_usable_hours
    end
  end

  def deduct_leave_time_usable_hours(
    leave_time_instance = self.leave_time,
    hours_to_deduct = self.hours,
    state = self.status
  )

    if leave_time_instance.present? && (state != 'rejected')
      leave_time_instance.deduct hours_to_deduct
    end
    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: hours_to_deduct)
  end

  def return_leave_time_usable_hours(
    leave_time_instance = LeaveTime.find_by(id: leave_time_id_was),
    hours_to_return = -self.hours_was,
    state = self.status_was
  )

    if leave_time_instance.present? && (state != 'rejected')
      leave_time_instance.deduct hours_to_return
    end
    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: hours_to_return,
                                returning?: true)
  end

  def hours_should_be_positive_integer
    errors.add(:end_time, :not_integer) unless self.hours > 0
    errors.add(:start_time, :should_be_earlier) unless self.end_time > self.start_time
  end
end

class LeaveApplication::ActiveRecord_Associations_CollectionProxy
  def leave_hours_within_month(type: 'all', year: Time.current.year, month: Time.current.month)
    beginning = WorkingHours.advance_to_working_time(Time.new(year, month, 1))
    closing   = WorkingHours.return_to_working_time(Time.new(year, month, 1).end_of_month)
    records.select { |r| r.is_leave_type?(type) }.reduce(0) do |result, la|
      if la.range_exceeded?(beginning, closing)
        valid_range = [la.start_time, beginning].max..[la.end_time, closing].min
        result + valid_range.min.working_time_until(valid_range.max) / 3600.0
      else
        result + la.hours
      end
    end
  end
end
