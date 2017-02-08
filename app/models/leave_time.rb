# frozen_string_literal: true
class LeaveTime < ApplicationRecord
  
  LEAVE_POOLS_CONFIG =
    DataHelper.each_keys_freeze Settings.leave_pools do |v|
      DataHelper.each_keys_to_sym v
    end
  LEAVE_POOLS_TYPES = LEAVE_POOLS_CONFIG.keys
  LEAVE_POOLS_TYPES_SYM = DataHelper.each_to_sym LEAVE_POOLS_TYPES
  LEAVE_POOLS_ALLOW_PRE_CREATION =
    Settings.leave_pools_misc.allow_pre_creation
  INFINITY_VALUE = Settings.leave_pools_misc.infinity_value

  after_initialize :init_from_type
  
  belongs_to :user, optional: false
  delegate :seniority, to: :user
  has_many :leave_applications

  validates :leave_type, :effective_date, :expiration_date, presence: true
  validate  :positive_range
  validate  :range_not_overlaps

  scope :personal, ->(user_id, leave_type, beginning, closing){
    overlaps(beginning, closing).find_by(user_id: user_id, leave_type: leave_type)
  }

  scope :get_employees_bonus, ->() {
    where("leave_type = ?", "bonus").order(user_id: :desc)
  }

  scope :overlaps, ->(beginning, closing) {
    where(
      "(leave_times.effective_date, leave_times.expiration_date) OVERLAPS (timestamp :beginning, timestamp :closing)",
      beginning: beginning, closing: closing
    )
  }

  scope :effective, ->(date = Time.current) {
    overlaps(date.beginning_of_day, date.end_of_day)
  }

  def deduct(hours)
    self.used_hours += hours
    self.usable_hours = quota - used_hours
    save!
  end

  def available?(requested_hours = 1)
    (new_record? ? LEAVE_POOLS_ALLOW_PRE_CREATION.include?(leave_type) : true) &&
      ((usable_hours > requested_hours) || config[:allow_overspend])
  end

  def display_used?
    config[:display] == 'used'.freeze
  end

  def display_usable?
    config[:display] == 'usable'.freeze
  end

  def leave_times_in_the_same_pool
    LeaveTime.where(leave_type: leave_type, user: user)
  end

  def previous
    leave_times_in_the_same_pool.order(expiration_date: :desc).first
  end

  private

  def config
    @config ||= LEAVE_POOLS_CONFIG[leave_type]
  end
  
  def init_from_type
    if new_record?
      quota = usable_hours = generate_init_value_from_config(config[:quota])
      effective_date = generate_effective_date if effective_date.nil?
      expiration_date = effective_date + generate_init_value_from_config(config[:effective])
    end
  end

  def generate_effective_date
    case config[:creation]
    when 'occurrence'
      leave_applications.first.start_time
    when 'prev_not_effective'
      previous.expiration_date
    end
  end

  def generate_init_value_from_config(config)
    case config[:type]
    when 'hours'
      config[:value]
    when 'duration'
      eval config[:value]
    when 'as_quota'
      quota
    when 'annual'
      DurationRangeToValue.new(config[:value]).get_from_duration(user.seniority(effective_date))
    when 'infinity'
      INFINITY_VALUE
    end
  end

  def positive_range
    unless expiration_date && effective_date && expiration_date >= effective_date
      errors.add(:effective_date, :range_should_be_positive)
    end
  end

  def range_not_overlaps
    if expiration_date && effective_date && overlaps?
      errors.add(:effective_date, :range_should_not_overlaps)
    end
  end
  
  def overlaps?
    LeaveTime.overlaps(effective_date, expiration_date)
      .where(user_id: user_id, leave_type: leave_type)
      .where.not(id: self.id).any?
  end

end
