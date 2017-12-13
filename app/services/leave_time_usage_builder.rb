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
      [date, intervals.inject(0) { |acc, elem| acc + elem.duration.in_hours }]
    end.to_h
  end

  def build_leave_time_usages
    ActiveRecord::Base.transaction do
      validate_application_covered_by_leave_time_interval

      @available_leave_times.each do |lt|
        @leave_hours_by_date.keys.each do |date|
          break if usable_hours_is_empty?(lt)
          next if corresponding_leave_hours_date_is_zero?(date) or !in_leave_time_inteval_range?(lt, date)
          deduct_leave_hours_by_date(lt, date)
        end
        stack_leave_time_usage_record(lt)
        break if leave_hours_by_date_is_empty?
      end

      if !leave_hours_by_date_is_empty?
        rollback_with_error_message unless @leave_application.special_type?
      else
        create_leave_time_usage
      end
    end
  end

  private

  def work_periods_by_date
    work_periods.group_by { |wp| wp.start_time.localtime.to_date }
  end

  def work_periods
    Daikichi::Config::Biz.periods.after(@leave_application.start_time).timeline
      .until(@leave_application.end_time).to_a
  end

  def validate_application_covered_by_leave_time_interval
    include_start_time = include_end_time = false
    @available_leave_times.each do |lt|
      include_start_time = true if lt.cover?(@leave_hours_by_date.keys.first) # leave_time start_date 跟 date 相同會不會 cover 到
      include_end_time = true if lt.cover?(@leave_hours_by_date.keys.last)
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

  def in_leave_time_inteval_range?(leave_time, date)
    date.between?(leave_time.effective_date, leave_time.expiration_date)
  end

  def stack_leave_time_usage_record(leave_time)
    @leave_time_usages.push(leave_time: leave_time, used_hours: leave_time.usable_hours_was - leave_time.usable_hours)
  end

  def leave_hours_by_date_is_empty?
    @leave_hours_by_date.values.all?(&:zero?)
  end

  def unless_remain_leave_hours_by_date
  end

  def rollback_with_error_message
    append_leave_application_error_message
    raise ActiveRecord::Rollback
  end

  def append_leave_application_error_message
    @leave_application.errors.add(:hours, :leave_time_not_sufficient)
    @leave_hours_by_date.each { |date, hours| @leave_application.errors.add(:hours, :lacking_hours, date: date.to_formatted_s('month_date'), hours: hours) unless hours.zero? }
  end

  def create_leave_time_usage
    @leave_time_usages.each do |lt_usage|
      @leave_application.leave_time_usages.create!(leave_time: lt_usage[:leave_time], used_hours: lt_usage[:used_hours])
    end
  end
end
