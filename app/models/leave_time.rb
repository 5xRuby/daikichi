# frozen_string_literal: true
class LeaveTime < ApplicationRecord
  belongs_to :user, optional: false

  BASIC_TYPES = %w(annual bonus personal sick).freeze
  MAX_ANNUAL_DAYS = Settings.leave_time.max_annual_days
  DAILY_HOURS = Settings.leave_time.daily_hour
  DAYS_IN_YEAR = Settings.leave_time.days_in_a_year # ignore leap year

  scope :personal, ->(user_id, leave_type, beginning, closing){
    overlaps(beginning, closing).find_by(user_id: user_id, leave_type: leave_type)
  }

  scope :get_employees_bonus, ->() {
    where("leave_type = ?", "bonus").order(user_id: :desc)
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

  validates :leave_type,      presence: true
  validates :effective_date,  presence: true
  validates :expiration_date, presence: true
  validate  :positive_range
  validate  :range_not_overlaps

  def init_quota
    return false if seniority < 1
    quota = quota_by_seniority
    unless leave_type == "bonus"
      return false if quota <= 0
    end
    self.attributes = {
      leave_type: leave_type,
      quota: quota,
      usable_hours: quota
    }
    save!
  end

  def deduct(hours)
    self.used_hours += hours
    self.usable_hours = quota - used_hours
    save!
  end

  private

  def quota_by_seniority
    if leave_type == "annual"
      annual_hours_by_seniority
    else
      days_by_leave_type * DAILY_HOURS
    end
  end

  ## Only calcualte when employees resign within a year

  def first_year_rate
    (days_by_leave_type * first_year_adjustment).round * DAILY_HOURS
  end

  def first_year_adjustment
    (Time.zone.now - user.join_date).to_i / 1.day / DAYS_IN_YEAR
  end

  def employed_for_the_first_year?
    user.employed_for_the_first_year?
  end

  #---------------------------

  def seniority
    user.seniority
  end

  def annual_hours_by_seniority
    days = annual_hour_index
    days = MAX_ANNUAL_DAYS if days > MAX_ANNUAL_DAYS
    days * DAILY_HOURS
  end

  def days_by_leave_type
    case leave_type
    when "annual" then 7
    when "bonus" then 0
    when "personal" then 7
    when "sick" then 30
    else 0
    end
  end

  def annual_hour_index
    base_day = 6.freeze

    case seniority
    when 0 then 0
    when 1 then 7
    when 2 then 10
    when (3..4) then 14
    when (5..9) then 15
    else seniority + base_day
    end
  end

  def overlaps?
    LeaveTime.overlaps(effective_date, expiration_date)
             .where(user_id: user_id, leave_type: leave_type)
             .where.not(id: self.id).any?
  end

  def positive_range
    unless self.expiration_date && self.effective_date && self.expiration_date >= self.effective_date
      errors.add(:effective_date, :range_should_be_positive)
    end
  end

  def range_not_overlaps
     if self.expiration_date && self.effective_date && overlaps?
       errors.add(:effective_date, :range_should_not_overlaps)
     end
  end
end
