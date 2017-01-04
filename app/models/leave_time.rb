# frozen_string_literal: true
class LeaveTime < ApplicationRecord
  belongs_to :user

  BASIC_TYPES = %w(annual bonus personal sick).freeze
  MAX_ANNUAL_DAYS = Settings.leave_time.max_annual_days
  DAILY_HOURS = Settings.leave_time.daily_hour 
  DAYS_IN_YEAR = Settings.leave_time.days_in_a_year # ignore leap year

  scope :current_year, ->(user_id, year=Time.now.year) {
    where(year: year, user_id: user_id)
  }

  scope :personal, ->(user_id, leave_type, year = Time.current.year){
    find_by(user_id: user_id, leave_type: leave_type, year: year)
  }

  scope :get_employees_bonus, ->(){
    where("leave_type = ?", "bonus").order(user_id: :desc)
  }

  validates :leave_type,
            uniqueness: { scope: [:user_id, :year], message: '已存在該假別' }

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

  def refill
    return false if seniority != 2 || refilled

    self.attributes = {
      quota: quota + DAILY_HOURS,
      usable_hours: usable_hours + DAILY_HOURS,
      refilled: true
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

  ## Only if the employee resigned within a year 

  def first_year_rate
    (days_by_leave_type * first_year_adjustment).round * DAILY_HOURS
  end

  def first_year_adjustment
    (Time.zone.now - user.join_date).to_i / 1.day / DAYS_IN_YEAR
  end

  #---------------------------

  def seniority
    user.seniority
  end

  def employed_for_the_first_year?
    user.employed_for_the_first_year?
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
end
