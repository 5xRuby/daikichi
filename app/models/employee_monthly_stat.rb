class EmployeeMonthlyStat
  def self.total_leave_times_hours(year, mon)
    result = CustomHash.new

    range_start = Time.zone.now.change(year: year, month: mon, day: 1, hour: 0)
    range_end = Time.zone.now.change(year: year, month: mon).end_of_month
    range = range_start .. range_end

    leaves_with_start_time_in_range = LeaveApplication.where(start_time: range, status: "approved")
    leaves_with_end_time_in_range = LeaveApplication.where(end_time: range, status: "approved")
    leaves = leaves_with_start_time_in_range.or(leaves_with_end_time_in_range)

    leaves.each do |leave|
      if range.cover?(leave.start_time) and range.cover?(leave.end_time)
        result[leave.user_id][leave.leave_type] += leave.hours
      elsif range.cover? leave.start_time
        result[leave.user_id][leave.leave_type] += leave.start_time.working_time_until(range_end) / 3600
      else
        result[leave.user_id][leave.leave_type] += range_start.working_time_until(leave.end_time) / 3600
      end
    end
    result
  end
end
