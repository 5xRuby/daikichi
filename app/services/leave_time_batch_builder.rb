# frozen_string_literal: true
class LeaveTimeBatchBuilder
  MONTHLY_LEED_DAYS         = Settings.leed_days.monthly
  JOIN_DATE_BASED_LEED_DAYS = Settings.leed_days.join_date_based

  def initialize(forced: false)
    @forced = forced
  end

  def automatically_import
    batch_join_date_based_import
    batch_monthly_import
    batch_weekly_import
  end

  private

  def batch_join_date_based_import
    leed_day = Time.current + JOIN_DATE_BASED_LEED_DAYS.days
    find_user_by_forced(User.valid, leed_day)
    return if @users.empty?
    @users.each do |user|
      if @forced
        LeaveTimeBuilder.new(user).join_date_based_import
      else
        LeaveTimeBuilder.new(user).join_date_based_import(prebuild: true)
      end
    end
  end

  def batch_monthly_import
    return if !end_of_working_month? && !@forced
    User.valid.find_each do |user|
      if @forced
        LeaveTimeBuilder.new(user).monthly_import
      else
        LeaveTimeBuilder.new(user).monthly_import(prebuild: true)
      end
    end
  end

  def batch_weekly_import
    return if !Time.current.monday? && !@forced
    User.valid.find_each do |user|
      if @forced
        LeaveTimeBuilder.new(user).weekly_import
      else
        LeaveTimeBuilder.new(user).weekly_import(prebuild: true)
      end
    end
  end

  def end_of_working_month?
    @end_of_working_month_bool ||= Daikichi::Config::Biz.time(MONTHLY_LEED_DAYS, :days).after(Time.current.beginning_of_day).to_date == Daikichi::Config::Biz.periods.before(Time.current.end_of_month).first.end_time.to_date
  end

  def reaching_join_date
    @reaching_join_date ||= Time.zone.today + JOIN_DATE_BASED_LEED_DAYS.days
  end

  def find_user_by_forced(valid_users, leed_day)
    if @forced
      @users = []
      valid_users.where.not(join_date: (Time.current.to_date)..(Time.current)).find_each.map { |user| @users << user if user.this_year_join_anniversary - leed_day.to_date <= 60 }
    else
      @users = valid_users.filter_by_join_date(reaching_join_date.month, reaching_join_date.day)
    end
  end
end
