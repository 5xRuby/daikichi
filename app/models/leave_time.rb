# frozen_string_literal: true
class LeaveTime < ApplicationRecord
  belongs_to :user

  BASIC_TYPES = %w(annual bonus personal sick).freeze
  MAX_ANNUAL_DAYS = 30
  DAILY_HOURS = 8
  DAYS_IN_YEAR = 365.0 # ignore leap year

  scope :current_year, ->(user_id) {
    where(year: Time.zone.today.year, user_id: user_id)
  }

  scope :personal, ->(user_id, leave_type){
    find_by(user_id: user_id, leave_type: leave_type)
  }

  scope :get_general_and_annual, ->(user_id, leave_type){
    leave_time = find_by user_id: user_id, leave_type: leave_type
    leave_time_for_annual = find_by user_id: user_id, leave_type: "annual"
    return leave_time, leave_time_for_annual
  }

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

  # main api
  def deduct(hours)
    if leave_type == "personal"
      calculate_personal! hours
    else
      calculate_general! hours
    end
  end

  def add_back(hours, annual_hours)
    calculate_general!(-hours)
    if annual_hours.positive?
      annual = LeaveTime.personal(user_id, "annual")
      annual.send :calculate_general!, -annual_hours
    end
  end

  private

  def quota_by_seniority
    if seniority < 1
      0
    elsif seniority == 1
      first_year_rate
    else
      normal_rate
    end
  end

  def normal_rate
    if leave_type == "annual"
      annual_hours_by_seniority
    else
      days_by_leave_type * DAILY_HOURS
    end
  end

  def first_year_rate
    (days_by_leave_type * first_year_adjustment).round * DAILY_HOURS
  end

  def first_year_adjustment
    (DAYS_IN_YEAR - user.join_date.yday) / DAYS_IN_YEAR
  end

  def seniority
    user.seniority(year)
  end

  def annual_hours_by_seniority
    days = days_by_leave_type + (seniority - 1)
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

  def calculate_general!(hours)
    self.used_hours += hours
    self.usable_hours = quota - used_hours
    save!
  end

  def calculate_personal!(hours)
    annual = self.class.find_by user_id: user_id, leave_type: "annual"
    delta = hours - annual.usable_hours
    if delta >= 0
      calculate_general! delta
      annual.send :become_empty!
    else
      annual.send :calculate_general!, hours
    end
    annual.save!
  end

  def become_empty!
    self.used_hours = self.quota
    self.usable_hours = 0
    save!
  end
end
