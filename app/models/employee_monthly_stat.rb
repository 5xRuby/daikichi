# frozen_string_literal: true
class EmployeeMonthlyStat
  def self.total_leave_times_hours(year, month)
    @year = year
    @month = month
    @range = range_start..range_end
    result = CustomHash.new
    leaves.each do |leave|
      result[leave.user_id][leave.leave_type] += leave_hours(leave)
    end
    result
  end

  private

  def leave_hours(leave)
    if @range.cover?(leave.start_time) and @range.cover?(leave.end_time)
      leave.hours
    elsif @range.cover?(leave.start_time)
      leave.start_time.working_time_until(range_end) / 3600
    else
      range_start.working_time_until(leave.end_time) / 3600
    end
  end

  def range_start
    Time.zone.now.change(year: @year, month: @month, day: 1, hour: 0)
  end

  def range_end
    Time.zone.now.change(year: @year, month: @month).end_of_month
  end

  def leaves_with_start_time_in_range
    LeaveApplication.where(start_time: @range, status: "approved")
  end

  def leaves_with_end_time_in_range
    LeaveApplication.where(end_time: @range, status: "approved")
  end

  def leaves
    leaves_with_start_time_in_range.or(leaves_with_end_time_in_range)
  end
end
