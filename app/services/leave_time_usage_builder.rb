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
      raise ActiveRecord::Rollback unless application_covered_by_leave_time_interval?

      @available_leave_times.each do |lt|
        iterate_leave_time_dates(lt) do |date|
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

  def application_covered_by_leave_time_interval?
    include_start_time = include_end_time = false
    @available_leave_times.each do |lt|
      include_start_time = true if lt.cover?(@leave_application.start_time) # leave_time start_date 跟 date 相同會不會 cover 到
      include_end_time = true if lt.cover?(@leave_application.end_time)
      break if include_start_time && include_end_time
    end
    include_start_time && include_end_time
  end

  def iterate_leave_time_dates(leave_time)
    la_start_date = @leave_application.start_time.to_date
    la_end_date = @leave_application.end_time.to_date
    start_date = la_start_date > leave_time.effective_date ? la_start_date : leave_time.effective_date
    end_date = la_end_date < leave_time.expiration_date ? la_end_date : leave_time.expiration_date
    start_date.upto(end_date) { |date| yield date unless weekday?(date) }
  end

  def weekday?(date)
    date.saturday? || date.sunday?
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
    @leave_hours_by_date.each_value { |v| raise ActiveRecord::Rollback unless v.zero? }
  end

  def create_leave_time_usage
    @leave_time_usages.each do |lt_usage|
      @leave_application.leave_time_usages.create!(leave_time: lt_usage[:leave_time], used_hours: lt_usage[:used_hours])
    end
  end
end
