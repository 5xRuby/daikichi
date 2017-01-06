# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  acts_as_paranoid
  paginates_per 8

  after_initialize :set_primary_id
  # FIXME: Checkif working when update duration of leave application
  before_create :deduct_leave_time_usable_hours
  before_destroy :return_leave_time_usable_hours

  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  has_many :leave_application_logs, foreign_key: "leave_application_uuid", primary_key: "uuid", dependent: :destroy

  validates :leave_type, :description, presence: true

  validate :hours_should_be_positive_integer
  # FIXME: Not working when update duration of leave application
  validate :has_enough_leave_time, on: :create
  validate :valid_advanced_leave_type?

  LEAVE_TYPE = %i(annual bonus personal sick).freeze
  STATUS = %i(pending approved rejected canceled).freeze

  include AASM
  include SignatureConcern

  scope :leave_within_range, ->(beginning = WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month),
                                closing   = WorkingHours.return_to_working_time(1.month.ago.end_of_month)) {
    where(
      '(leave_applications.start_time, leave_applications.end_time) OVERLAPS (timestamp :beginning, timestamp :closing)',
      beginning: beginning, closing: closing
    )
  }

  aasm column: :status do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, after: proc { |manager| sign(manager) } do
      transitions to: :approved, from: [:pending]
    end

    event :reject, after: [proc { |manager| sign(manager) }, :return_leave_time_usable_hours] do
      transitions to: :rejected, from: [:pending]
    end

    event :revise, after: :revise_leave_time_usable_hours do
      transitions to: :pending, from: [:pending, :approved, :rejected]
    end

    event :cancel, after: :return_leave_time_usable_hours do
      transitions to: :canceled, from: [:pending, :rejected]
      transitions to: :canceled, from: :approved, unless: :happened?
    end
  end

  scope :with_status, -> (status) { where(status: status) }

  # class method
  class << self
    def with_year(year = Time.now.year)
      t = Time.new(year)
      range = (t.beginning_of_year .. t.end_of_year)
      leaves_start_time_included = where(start_time: range )
      leaves_end_time_included = where(end_time: range )
      leaves_start_time_included.or(leaves_end_time_included)
    end
  end

  def happened?
    Time.current > self.start_time
  end

  def leave_time
    @leave_time ||= LeaveTime.personal(self.user_id, self.leave_type, self.start_time, self.end_time)
  end

  def range_exceeded?(beginning = WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month), closing = WorkingHours.return_to_working_time(1.month.ago.end_of_month))
    beginning > self.start_time || closing < self.end_time
  end

  def self.leave_hours_within(beginning = WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month), closing = WorkingHours.return_to_working_time(1.month.ago.end_of_month))
    self.leave_within_range(beginning, closing).reduce(0) do |result, la|
      if la.range_exceeded?(beginning, closing)
        @valid_range = [la.start_time, beginning].max..[la.end_time, closing].min
        result + @valid_range.min.working_time_until(@valid_range.max) / 3600.0
      else
        result + la.hours
      end
    end
  end

  def is_leave_type?(type = :all)
    return true if type.to_sym == :all
    self.leave_type.to_sym == type.to_sym
  end

  private

  def set_primary_id
    self.uuid ||= SecureRandom.uuid
  end

  def deduct_leave_time_usable_hours
    assign_hours

    leave_time.deduct hours
    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: hours)
  end

  def revise_leave_time_usable_hours
    assign_hours
    save!

    log = leave_application_logs.last
    delta = log.returning? ? hours : (hours - log.amount)

    leave_time.deduct delta
    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: hours)
  end

  def return_leave_time_usable_hours
    leave_time = self.leave_time

    log = leave_application_logs.last
    leave_time.deduct(-log.amount) unless log.returning?

    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: log.amount,
                                returning?: true)
  end

  def assign_hours
    self.hours = start_time.working_time_until(end_time) / 3600.0
  end

  def hours_should_be_positive_integer
    errors.add(:end_time, :not_integer) unless (((end_time - start_time) / 3600.0) % 1).zero?
    errors.add(:start_time, :should_be_earlier) unless end_time > start_time
  end

  def valid_advanced_leave_type?
    if start_time.year > Time.current.year && leave_type != 'annual'
      errors.add(:leave_type, :only_take_annual_leave_year_before)
    end
  end

  def has_enough_leave_time
    unless self.leave_time.present? && assign_hours < (self.leave_time.try(:usable_hours) || 0)
      errors.add(:end_time, :not_enough_leave_time)
    end
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
