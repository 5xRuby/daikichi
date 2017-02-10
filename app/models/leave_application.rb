# frozen_string_literal: true
class LeaveApplication < ApplicationRecord

  include AASM
  include SignatureConcern
  
  STATUS = %i(pending approved rejected canceled).freeze

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

  MAX_PRE_APPLICATION = eval Settings.leave_application_misc.max_pre_application
  MAX_LEAVE_TO_APPLICABLE_BEFORE = DataHelper.each_keys_freeze(Settings.leave_application_misc.max_leave_to_applicable_before) {|v| DurationRangeToValue.new(v)}

  acts_as_paranoid
  paginates_per 8

  after_initialize :set_primary_id
  before_validation :assign_hours
  before_validation :pre_create_leave_time_if_allowed, on: :create
  before_validation :bind_leave_time_if_exist, on: :create
  before_save :ensure_leave_time_hours_correct

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

  def just_created_a_leave_time?
    @just_created_a_leave_time
  end

  private

  def config(key = nil, default = nil)
    @config ||= LEAVE_APPLICATION_TYPES_CONFIG[self.leave_type]
    if key.nil?
      @config
    else
      config.nil? ? default : config[key]
    end
  end

  def set_primary_id
    self.uuid ||= SecureRandom.uuid
  end
  
  def assign_hours
    self.hours = start_time.working_time_until(end_time) / 3600.0
  end

  def pre_create_leave_time_if_allowed
    leave_time_tmp.save! if leave_time_tmp.present? && leave_time_tmp.new_record? && leave_time_tmp.allow_pre_creation?
  end

  def bind_leave_time_if_exist
    self.leave_time = leave_time_tmp if leave_time_tmp.present? && !leave_time_tmp.new_record?
  end

  def bind_and_make_leave_time_exist
    if leave_time_tmp.new_record?
      @just_created_a_leave_time = leave_time_tmp.save!
      self.leave_time = leave_time_tmp
      self.save!
    end
  end
  
  def leave_time_tmp
    @leave_time_tmp ||= self.leave_time || pick_or_gen_leave_time
  end
  
  def pick_or_gen_leave_time
    leave_time_candidates = []
    config(:pool, []).each do |pool_type|
      pool = LeaveTime.get_from_pool(self.user, pool_type, self.start_time, self.end_time)
      leave_time_candidates += 
        pool.present? ? pool : [LeaveTime.new(user: user, leave_type: pool_type, new_by: self)]
    end
    leave_time_candidates.each do |lt|
      if lt.available? self.hours
        return lt
      end
    end
    nil
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
    
    if leave_time_instance.present? && (state != 'rejected'.freeze)
      leave_time_instance.deduct hours_to_deduct
    end
    LeaveApplicationLog.create!(leave_application_uuid: uuid,
                                amount: hours_to_deduct)
  end

  def return_leave_time_usable_hours(
    leave_time_instance = LeaveTime.find_by_id(leave_time_id_was),
    hours_to_return = -self.hours_was,
    state = self.status_was
  )

    if leave_time_instance.present? && (state != 'rejected'.freeze)
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

  def within_applicable_time
    unless applicable = config(:applicable)
      errors.add(:leave_type, :leave_type_not_applicable)
    else
      max_leave = MAX_LEAVE_TO_APPLICABLE_BEFORE[applicable].get_from_time_diff(start_time, end_time)
      time_before_leave = start_time - Time.now
      if (max_leave.nil? ? false : (time_before_leave < max_leave.to_i)) || (time_before_leave > MAX_PRE_APPLICATION)
        errors.add(:start_time, :not_within_applicable_time)
      end
    end
  end

  def has_enough_leave_time
    if leave_time_id_changed? || new_record?
      if leave_time_tmp.present?
        unless leave_time_tmp.available? hours
          errors.add(:end_time, :not_enough_leave_time)
        end
      else
        errors.add(:leave_type, :no_leave_time_available)
      end
    elsif hours_changed?
      unless leave_time_tmp.available? (hours - hours_was)
        errors.add(:end_time, :not_enough_leave_time)
      end

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

