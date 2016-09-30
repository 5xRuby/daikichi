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
    if leave_type == "personal"
      self.deduct_personal hours
    else
      self.deduct_general hours
    end
  end

  def deduct_general(hours)
    self.used_hours += hours
    self.usable_hours = quota - used_hours
    save!
  end

  def deduct_personal(hours)
    annual = self.class.find_by(user_id: user_id, leave_type: "annual")
    delta = ( hours >= 0 ? (hours - annual.usable_hours) : (hours + self.used_hours) )
    if hours >= 0
      if delta <= 0
        annual.deduct_general hours
      else
        self.deduct_general delta
        annual.become_empty!
      end
    else
      if delta >= 0
        self.deduct_general hours
      else
        annual.deduct_general delta
        self.become_full!
      end
    end
    annual.save!
  end

  def become_empty!
    self.used_hours = self.quota
    self.usable_hours = 0
    save!
  end

  def become_full!
    self.used_hours = 0
    self.usable_hours = self.quota
    save!
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

  #def empty?
    #self.usable_hours == 0
  #end

  #def full?
    #self.used_hours == 0
  #end
end
