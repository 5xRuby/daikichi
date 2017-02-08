# frozen_string_literal: true
class LeaveApplication < ApplicationRecord

  include AASM
  include SignatureConcern
  
  LEAVE_APPLICATION_TYPES_CONFIG =
    DataHelper.each_keys_freeze Settings.leave_application_types do |v|
      DataHelper.each_keys_to_sym v
    end
  LEAVE_APPLICATION_TYPES = LEAVE_APPLICATION_TYPES_CONFIG.keys
  LEAVE_APPLICATION_TYPES_SELECTABLE = LEAVE_APPLICATION_TYPES.delete_if do |x|
    LEAVE_APPLICATION_TYPES_CONFIG[x][:applicable].nil?
  end
  LEAVE_APPLICATION_TYPES_SYM = DataHelper.each_to_sym LEAVE_APPLICATION_TYPES
  LEAVE_APPLICATION_TYPES_SELECTABLE_SYM = DataHelper.each_to_sym LEAVE_APPLICATION_TYPES_SELECTABLE

  STATUS = %i(pending approved rejected canceled).freeze

  MAX_LEAVE_TO_APPLICABLE_BEFORE = DataHelper.each_keys_freeze(Settings.max_leave_to_applicable_before) {|v| DurationRangeToValue.new(v)}

  acts_as_paranoid
  paginates_per 8

  after_initialize :set_primary_id
  before_validation :assign_hours
  before_validation :set_leave_time, on: :create
  before_save :ensure_leave_time_hours_correct
  before_save :auto_approve_if_allow

  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  belongs_to :leave_time
  has_many :leave_application_logs, foreign_key: "leave_application_uuid", primary_key: "uuid", dependent: :destroy

  validates :leave_type, :description, :start_time, :end_time, presence: true
  
  validate :hours_should_be_positive_integer
  validate :within_applicable_time, on: :create
  validate :has_enough_leave_time
  
  scope :leave_within_range, ->(beginning = WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month),
                                closing   = WorkingHours.return_to_working_time(1.month.ago.end_of_month)) {
    where(
      '(leave_applications.start_time, leave_applications.end_time) OVERLAPS (timestamp :beginning, timestamp :closing)',
      beginning: beginning, closing: closing
    )
  }
  scope :with_status, -> (status) { where(status: status) }

  aasm column: :status do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, after: [proc { |manager| sign(manager) }, :bind_leave_time] do
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
      range = (t.beginning_of_year .. t.end_of_year)
      leaves_start_time_included = where(start_time: range )
      leaves_end_time_included = where(end_time: range )
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

  def config
    @config ||= LEAVE_APPLICATION_TYPES_CONFIG[leave_type]
  end

  def set_primary_id
    self.uuid ||= SecureRandom.uuid
  end
  
  def assign_hours
    hours = start_time.working_time_until(end_time) / 3600.0
  end

  def set_leave_time(create_leave_time = false)
    leave_time_tmp = get_leave_time
    new_record = leave_time_tmp.new_record?
    leave_time = unless new_record && !create_leave_time
      if new_record
        leave_time_tmp.save!
      end
      leave_time_tmp
    end
  end

  def bind_leave_time
    set_leave_time true
  end
  
  def get_leave_time
    config[:pool].each do |pool_type|
      leave_time_candidate =
        LeaveTime.personal(self.user_id, pool_type, self.start_time, self.end_time).first ||
        LeaveTime.new(user: user, leave_type: pool_type)
      if leave_time_candidate.available? hours
        return leave_time_candidate
      end
    end
  end

  def ensure_leave_time_hours_correct
    if leave_time_id_changed? || hours_changed? || status_changed?
      deduct_leave_time_usable_hours
      return_leave_time_usable_hours
    end
  end

  def deduct_leave_time_usable_hours(
    leave_time_instance = self.leave_time,
    hours_to_deduct = hours,
    state = status
  )
    
    if leave_time_instance.presence? && (state != 'rejected'.freeze)
      leave_time_instance.deduct hours
    end
    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: hours)
  end

  def return_leave_time_usable_hours(
    leave_time_instance = LeaveTime.find_by_id(leave_time_id_was),
    hours_to_return = hours_was,
    state = status_was
  )

    if leave_time_instance.presence? && (state != 'rejected'.freeze)
      leave_time_instance.deduct hours
    end
    leave_time_instance.deduct -hours_to_return if leave_time_instance.present?
    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: hours)
    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: hours_to_return,
                                returning?: true)
  end

  def auto_approve_if_allow
    if config[:auto_approve]
      approve!
    end
  end

  def hours_should_be_positive_integer
    errors.add(:end_time, :not_integer) unless (((end_time - start_time) / 3600.0) % 1).zero?
    errors.add(:start_time, :should_be_earlier) unless end_time > start_time
  end

  def within_applicable_time
    unless applicable = config[:applicable]
      errors.add(:leave_type, :leave_type_not_applicable)
    end
    max_leave = MAX_LEAVE_TO_APPLICABLE_BEFORE[config[:applicable]].get_from_time_diff(start_time, end_time)
    if max_leave.nil? ? false : (start_time - Time.now) < max_leave.to_i
      errors.add(:start_time, :not_within_applicable_time)
    end
  end

  def has_enough_leave_time
    unless leave_time.present? && leave_time.available?(hours)
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

