# frozen_string_literal: true
class LeaveTimeBuilder
  MONTHLY_LEAVE_TYPES = Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'monthly' }
  JOIN_DATE_BASED_LEAVE_TYPES = Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'join_date_based' }

  def initialize(user)
    @user = user
  end

  def automatically_import
    monthly_import
    join_date_based_import
  end

  def join_date_based_import(prebuild: false)
    JOIN_DATE_BASED_LEAVE_TYPES.each do |leave_type, config|
      build_join_date_based_leave_types(leave_type, config, prebuild)
    end
  end

  def monthly_import(prebuild: false)
    MONTHLY_LEAVE_TYPES.each do |leave_type, config|
      build_monthly_leave_types(leave_type, config, prebuild)
    end
  end

  private

  def build_join_date_based_leave_types(leave_type, config, prebuild)
    return unless user_can_have_leave_type?(@user, config)
    quota = extract_quota(config, @user, prebuild: prebuild)
    join_anniversary = @user.next_join_anniversary
    @user.leave_times.create(
      leave_type: leave_type,
      quota: quota,
      usable_hours: quota,
      used_hours: 0,
      effective_date: join_anniversary,
      expiration_date: join_anniversary + 1.year - 1.day
    )
  end

  def build_monthly_leave_types(leave_type, config, prebuild)
    @effective_date  = prebuild ? Time.zone.today.next_month.beginning_of_month : Time.zone.today
    @expiration_date = prebuild ? Time.zone.today.next_month.end_of_month : Time.zone.today.end_of_month
    quota = extract_quota(config, @user, prebuild: prebuild)
    @user.leave_times.create(
      leave_type: leave_type,
      quota: quota,
      usable_hours: quota,
      used_hours: 0,
      effective_date: @effective_date,
      expiration_date: @expiration_date
    )
  end

  def extract_quota(config, user, prebuild: false)
    return config['quota'] if config['quota'].is_a? Integer
    seniority = prebuild ? user.seniority(user.next_join_anniversary) : user.seniority
    return config['quota']['maximum_quota'] if seniority >= config['quota']['maximum_seniority']
    config['quota']['values'][seniority.to_s.to_sym] * 8
  end

  def user_can_have_leave_type?(user, config)
    return true if config['quota'].is_a? Integer
    config['quota']['type'] != 'seniority_based' || user.fulltime?
  end
end
