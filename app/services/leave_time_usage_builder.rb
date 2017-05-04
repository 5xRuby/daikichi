# frozen_string_literal: true
class LeaveTimeUsageBuilder
  def initialize(leave_application)
    @leave_application = leave_application
  end

  def leave_hours_by_date
    work_periods_by_date.map do |date, intervals|
      [date, intervals.inject(0) { |result, interval| result + interval.duration.in_hours }]
    end.to_h
  end

  private

  def work_periods_by_date
    work_periods.group_by { |wp| wp.start_time.localtime.to_date }
  end

  def work_periods
    Biz.periods.after(@leave_application.start_time).timeline
      .until(@leave_application.end_time).to_a
  end
end
