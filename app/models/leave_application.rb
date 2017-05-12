# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  include AASM
  include SignatureConcern

  enum status:     Settings.leave_applications.statuses
  enum leave_type: Settings.leave_applications.leave_types

  acts_as_paranoid
  paginates_per 8

  after_initialize :set_primary_id
  before_validation :assign_hours
  after_create :create_leave_time_usages
  after_update :update_leave_time_usages
  
  belongs_to :user
  belongs_to :manager, class_name: 'User', foreign_key: 'manager_id'
  belongs_to :leave_time
  has_many   :leave_time_usages
  has_many   :leave_application_logs, foreign_key: 'leave_application_uuid', primary_key: 'uuid', dependent: :destroy

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

    event :approve, after: [proc { |manager| sign(manager) }] do
      transitions to: :approved, from: :pending, after: :transfer_locked_hours_to_used_hours
    end

    event :reject, after: proc { |manager| sign(manager) } do
      transitions to: :rejected, from: :pending, after: :return_leave_time_usable_hours
    end

    event :revise, after: proc { |params| update_leave_application(params) } do
      transitions to: :pending, from: [:pending, :approved]
    end

    event :cancel do
      transitions to: :canceled, from: :pending, after: :return_leave_time_usable_hours 
      transitions to: :canceled, from: :approved, unless: :happened?, after: :return_approved_application_usable_hours
    end
  end

  class << self
    def with_year(year = Time.current.year)
      t = Time.zone.local(year)
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

  def available_leave_times
    self.user.leave_times
      .where(leave_type: Settings.leave_applications.available_quota_types.send(self.leave_type))
      .where('usable_hours > 0')
      .overlaps(start_time.beginning_of_day, end_time.end_of_day)
      .order(order_by_sequence)
      .order(:expiration_date, :usable_hours)
  end

  private

  def set_primary_id
    self.uuid ||= SecureRandom.uuid
  end

  def assign_hours
    self.hours = auto_calculated_minutes / 60
  end

  def auto_calculated_minutes
    return @minutes = 0 unless start_time && end_time
    @minutes ||= $biz.within(start_time, end_time).in_minutes
  end

  def hours_should_be_positive_integer
    return if self.errors[:start_time].any? or self.errors[:end_time].any?
    errors.add(:end_time, :not_integer) if (@minutes % 60).nonzero? || !self.hours.positive?
    errors.add(:start_time, :should_be_earlier) unless self.end_time > self.start_time
  end

  def order_by_sequence
    'array_position(Array%s, leave_type::TEXT)' % Settings.leave_applications.available_quota_types.send(self.leave_type).to_s.tr('"', "'")
  end

  def create_leave_time_usages
    raise ActiveRecord::Rollback unless LeaveTimeUsageBuilder.new(self).build_leave_time_usages
  end

  def update_leave_application(resource_params)
    self.update(resource_params)
  end

  def update_leave_time_usages
    return unless self.start_time_changed? or self.end_time_changed?

    case aasm.from_state
    when :pending then return_leave_time_usable_hours
    when :approved then return_approved_application_usable_hours
    end
    create_leave_time_usages
  end

  def transfer_locked_hours_to_used_hours
    self.leave_time_usages.each { |usage| usage.leave_time.use_hours!(usage.used_hours) }
  end

  def revert_used_hours_to_locked_hours
    self.leave_time_usages.each { |usage| usage.leave_time.unuse_and_lock_hours!(usage.used_hours) }
  end

  def return_leave_time_usable_hours
    self.leave_time_usages.each do |usage|
      usage.leave_time.unlock_hours!(usage.used_hours)
      usage.destroy
    end
  end

  def return_approved_application_usable_hours
    self.leave_time_usages.each do |usage|
      usage.leave_time.unuse_hours!(usage.used_hours)
      usage.destroy
    end
  end
end

class LeaveApplication::ActiveRecord_Associations_CollectionProxy
  def leave_hours_within_month(type: 'all', year: Time.current.year, month: Time.current.month)
    beginning = WorkingHours.advance_to_working_time(Time.zone.local(year, month, 1))
    closing   = WorkingHours.return_to_working_time(Time.zone.local(year, month, 1).end_of_month)
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
