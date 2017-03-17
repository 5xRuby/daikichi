# frozen_string_literal: true
class LeaveTime < ApplicationRecord
  LEAVE_POOLS_CONFIG =
    DataHelper.each_keys_freeze Settings.leave_pools do |v|
      v = DataHelper.each_keys_to_sym v
      [:quota, :effective].each do |k|
        v[k] = DataHelper.each_keys_to_sym v[k]
      end
      v
    end
  LEAVE_POOLS_TYPES = LEAVE_POOLS_CONFIG.keys
  LEAVE_POOLS_TYPES_SYM = DataHelper.each_to_sym LEAVE_POOLS_TYPES
  LEAVE_POOLS_ALLOW_PRE_CREATION =
    Settings.leave_pools_misc.allow_pre_creation
  LEAVE_POOLS_AUTO_CREATION =
    Settings.leave_pools_misc.auto_creation
  INFINITY_VALUE = Settings.leave_pools_misc.infinity_value

  attr_accessor :new_by

  after_initialize :init_from_type
  before_save :init_from_type, on: :create

  belongs_to :user, optional: false
  delegate :seniority, :name, to: :user
  has_many :leave_applications

  validates :leave_type, :effective_date, :expiration_date, :quota, :usable_hours, :used_hours, :user, presence: true
  validates :quota,        numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :usable_hours, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :used_hours,   numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate  :positive_range

  scope :get_from_pool, ->(user, pool_type, start_time, end_time) {
    belong_to(user).where(leave_type: pool_type).overlaps(start_time, end_time)
  }

  scope :belong_to, ->(user) {
    where(user: user)
  }

  scope :personal, ->(user_id, leave_type, beginning, closing) {
    overlaps(beginning, closing).find_by(user_id: user_id, leave_type: leave_type)
  }

  scope :overlaps, ->(beginning, closing) {
    where(
      '(leave_times.effective_date, leave_times.expiration_date) OVERLAPS (timestamp :beginning, timestamp :closing)',
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
    (new_record? ? self.auto_creation? : true) &&
      (((usable_hours >= requested_hours) && (used_hours >= -requested_hours)) || config(:allow_overspend))
  end

  def allow_pre_creation?
    LEAVE_POOLS_ALLOW_PRE_CREATION.include? config(:creation)
  end

  def auto_creation?
    LEAVE_POOLS_AUTO_CREATION.include?(config(:creation))
  end

  def used_hours_if_allow
    display_used? ? used_hours : ''
  end

  def usable_hours_if_allow
    display_usable? ? usable_hours : ''
  end

  def display_used?
    config(:display) == 'used'
  end

  def display_usable?
    config(:display) == 'usable'
  end

  def leave_times_in_the_same_pool
    LeaveTime.where(leave_type: self.leave_type, user: user)
  end

  def previous
    leave_times_in_the_same_pool.order(expiration_date: :desc).first
  end

  def leave_type_valid?
    LEAVE_POOLS_TYPES.include? self.leave_type
  end

  private

  def config(key = nil, default = nil)
    @config ||= LEAVE_POOLS_CONFIG[self.leave_type]
    if key.nil?
      @config
    else
      config.nil? ? default : config[key]
    end
  end

  def init_from_type
    if new_record? && leave_type_valid? && !@inited_from_type
      self.usable_hours ||= self.quota ||= generate_init_value_from_config(config(:quota))
      self.effective_date ||= @start_time || generate_effective_date
      if (effective = generate_init_value_from_config(config[:effective])) && effective_date.present?
        self.expiration_date ||= self.effective_date + effective
      end
      @inited_from_type = true
    end
  end

  def generate_effective_date
    case config(:creation)
    when 'occurrence'
      new_by.start_time
    when 'prev_not_effective'
      previous.present? ? previous.expiration_date : Time.current
    end
  end

  def generate_init_value_from_config(c)
    case c[:type]
    when 'hours'
      c[:value]
    when 'duration'
      eval c[:value]
    when 'as_quota'
      quota
    when 'annual'
      if user.present?
        seniority = self.effective_date.present? ? self.user.seniority(self.effective_date) : 1.day
        DurationRangeToValue.new(c[:value]).get_from_duration(seniority)
      end
    when 'infinity'
      INFINITY_VALUE
    end
  end

  def positive_range
    unless expiration_date && effective_date && expiration_date >= effective_date
      errors.add(:effective_date, :range_should_be_positive)
    end
  end

  def overlaps?
    LeaveTime.overlaps(effective_date, expiration_date)
      .where(user_id: user_id, leave_type: self.leave_type)
      .where.not(id: self.id).any?
  end
end
