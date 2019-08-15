# frozen_string_literal: true

class EmployeeMonthlyStat
  def self.total_leave_times_hours(year, month)
    range_start = Time.zone.now.change(year: year, month: month, day: 1, hour: 0)
    range_end = Time.zone.now.change(year: year, month: month).end_of_month
    @range = range_start..range_end

    leaves_with_start_time_in_range = LeaveApplication.where(start_time: @range, status: 'approved')
    leaves_with_end_time_in_range = LeaveApplication.where(end_time: @range, status: 'approved')
    leaves = leaves_with_start_time_in_range.or(leaves_with_end_time_in_range)

    result = CustomHash.new
    leaves.each do |leave|
      result[leave.user_id][leave.leave_type] += leave_hours(leave)
    end
    result
  end

  def self.leave_hours(leave)
    if @range.cover?(leave.start_time) and @range.cover?(leave.end_time)
      leave.hours
    elsif @range.cover?(leave.start_time)
      Daikichi::Config::Biz.within(leave.start_time, @range.end).in_minutes / 60.0
    else
      Daikichi::Config::Biz.within(@range.begin, leave.end_time).in_minutes / 60.0
    end
  end
end
