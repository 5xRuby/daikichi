# frozen_string_literal: true
class LeaveTimeUsageBuilder
  def initialize(leave_application)
    @leave_application = leave_application
    @available_leave_times = @leave_application.available_leave_times
    @leave_hours_by_date = leave_hours_by_date
    @leave_time_usages = []
  end

  def leave_hours_by_date
    work_periods_by_date.map do |date, intervals|
      [date, intervals.inject(0) { |result, interval| result + interval.duration.in_hours }]
    end.to_h
  end

  def build_leave_time_usages
    ActiveRecord::Base.transaction do
      validate_application_covered_by_leave_time_interval

      @available_leave_times.each do |lt|
        @leave_hours_by_date.keys.each do |date|
          break if usable_hours_is_empty?(lt)
          next if corresponding_leave_hours_date_is_zero?(date)
          deduct_leave_hours_by_date(lt, date)
        end
        stack_leave_time_usage_record(lt)
      end

      unless_remain_leave_hours_by_date
      create_leave_time_usage
    end
  end

  private

  def work_periods_by_date
    work_periods.group_by { |wp| wp.start_time.localtime.to_date }
  end

  def work_periods
    $biz.periods.after(@leave_application.start_time).timeline
      .until(@leave_application.end_time).to_a
  end

  def validate_application_covered_by_leave_time_interval
    include_start_time = include_end_time = false
    @available_leave_times.each do |lt|
      include_start_time = true if lt.cover?(@leave_application.start_time)
      include_end_time = true if lt.cover?(@leave_application.end_time)
      break if include_start_time && include_end_time
    end

    rollback_with_error_message unless include_start_time && include_end_time
  end

  def usable_hours_is_empty?(leave_time)
    leave_time.usable_hours.zero?
  end

  def deduct_leave_hours_by_date(leave_time, date)
    if leave_time.usable_hours > @leave_hours_by_date[date]
      leave_time.usable_hours -= @leave_hours_by_date[date]
      @leave_hours_by_date[date] = 0
    else
      @leave_hours_by_date[date] -= leave_time.usable_hours
      leave_time.usable_hours = 0
    end
  end

  def corresponding_leave_hours_date_is_zero?(date)
    @leave_hours_by_date[date].zero?
  end

  def stack_leave_time_usage_record(leave_time)
    @leave_time_usages.push(leave_time: leave_time, used_hours: leave_time.usable_hours_was - leave_time.usable_hours)
  end

  def unless_remain_leave_hours_by_date
    @leave_hours_by_date.each_value { |v| rollback_with_error_message unless v.zero? }
  end

  def rollback_with_error_message
    append_leave_application_error_message
    raise ActiveRecord::Rollback
  end

  def append_leave_application_error_message
    @leave_application.errors.add(:hours, I18n.t('warnings.leave_time_not_sufficient'))
    @leave_hours_by_date.each_pair { |date, hours| @leave_application.errors.add(:hours, "\n" + date.strftime('%Y/%m/%d') + ' 缺少額度：' + hours.to_s + ' 小時') unless hours.zero? }
  end

  def create_leave_time_usage
    @leave_time_usages.each do |lt_usage|
      @leave_application.leave_time_usages.create!(leave_time: lt_usage[:leave_time], used_hours: lt_usage[:used_hours])
    end
  end
end
