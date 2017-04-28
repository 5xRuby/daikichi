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
      raise ActiveRecord::Rollback unless leave_time_covered_application_time_interval?

      @available_leave_times.each do |lt|
        @used_hour_count = 0
        iterate_leave_time_dates(lt) do |date|
          next if corresponding_leave_hours_date_is_zero?(date)
          if usable_hours_affordable?(lt, date)
            fill_all_leave_hours_by_date(date)
          else
            fill_leave_hours_by_date_with_remain_leave_time(lt, date)
            break
          end
        end
        @leave_time_usages.push(leave_time: lt, used_hours: @used_hour_count)
      end

      raise ActiveRecord::Rollback if remain_leave_hours_by_date?
      create_leave_time_usage_and_lock_hours
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

  def leave_time_covered_application_time_interval?
    include_start_time = include_end_time = false
    @available_leave_times.each do |lt|
      include_start_time = true if lt.cover?(@leave_application.start_time.to_date)
      include_end_time = true if lt.cover?(@leave_application.end_time.to_date)
    end
    include_start_time && include_end_time
  end

  def iterate_leave_time_dates(leave_time)
    la_start_date = @leave_application.start_time.to_date
    la_end_date = @leave_application.end_time.to_date
    start_date = la_start_date > leave_time.effective_date ? la_start_date : leave_time.effective_date
    end_date = la_end_date < leave_time.expiration_date ? la_end_date : leave_time.expiration_date
    start_date.upto(end_date) { |date| yield date }
  end

  def usable_hours_affordable?(leave_time, date)
    @used_hour_count + @leave_hours_by_date[date] <= leave_time.usable_hours
  end

  def fill_all_leave_hours_by_date(date)
    @used_hour_count += @leave_hours_by_date[date]
    @leave_hours_by_date[date] = 0
  end

  def fill_leave_hours_by_date_with_remain_leave_time(leave_time, date)
    remain_hours = @used_hour_count + @leave_hours_by_date[date] - lt.usable_hours
    @used_hour_count = lt.usable_hours
    @leave_hours_by_date[date] = remain_hours
  end

  def corresponding_leave_hours_date_is_zero?(date)
    @leave_hours_by_date[date].nil? || @leave_hours_by_date[date].zero?
  end

  def remain_leave_hours_by_date?
    @leave_hours_by_date.each_value { |v| return true unless v.zero? }
    false
  end

  def create_leave_time_usage_and_lock_hours
    @leave_time_usages.each do |lt_usage|
      create_leave_time_usage(lt_usage[:leave_time], lt_usage[:used_hours])
      lock_leave_time_hours(lt_usage[:leave_time], lt_usage[:used_hours])
    end
  end

  def create_leave_time_usage(leave_time, used_hours)
    leave_time_usage = @leave_application.leave_time_usages.new
    leave_time_usage.leave_time = leave_time
    leave_time_usage.used_hours = used_hours
    leave_time_usage.save!
  end

  def lock_leave_time_hours(leave_time, used_hours)
    leave_time.lock_hours used_hours
  end
end
