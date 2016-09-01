class EmployeeMonthlyStat
  def self.total_leave_times_hours(year, mon)
    result = CustomHash.new

    range_begin_at = Time.zone.now.change(year: year, month: mon, day: 1, hour: 0)
    range_end_at = Time.zone.now.change(year: year, month: mon).end_of_month
    range = range_begin_at .. range_end_at

    leaves = LeaveApplication.where(sign_date: range, status: "approved")
    leaves.each do |leave|
      result[leave.user_id][leave.leave_type] += leave.hours
    end
    return result
  end
end
