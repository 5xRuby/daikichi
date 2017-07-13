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
  end

  private

  def batch_join_date_based_import
    leed_day = Time.current + JOIN_DATE_BASED_LEED_DAYS.days
    users = if @forced
              User.valid.where('(EXTRACT(MONTH FROM join_date), EXTRACT(DAY FROM join_date)) <= (:month, :date)', month: leed_day.month, date: leed_day.day)
                        .where.not(join_date: ((Time.current - 1.year).to_date)..(Time.current))
            else
              User.valid.filter_by_join_date(reaching_join_date.month, reaching_join_date.day)
            end
    return unless users.present?
    users.find_each do |user|
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

  def end_of_working_month?
    @end_of_working_month_bool ||= Daikichi::Config::Biz.time(MONTHLY_LEED_DAYS, :days).after(Time.current.beginning_of_day).to_date == Daikichi::Config::Biz.periods.before(Time.current.end_of_month).first.end_time.to_date
  end

  def reaching_join_date
    @reaching_join_date ||= Time.zone.today + JOIN_DATE_BASED_LEED_DAYS.days
  end
end
