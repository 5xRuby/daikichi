class Month
  def self.leave_application_hours_stat(year=Time.zone.now.year, mon=Time.zone.now.mon)
    stat = Stat.new
    year, mon = year.to_i, mon.to_i
    range_begin_at = Time.zone.now.change(year: year, month: mon, day: 1, hour: 0)
    range_end_at = Time.zone.now.change(year: year, month: mon).end_of_month
    range = range_begin_at .. range_end_at

    leaves = LeaveApplication.where(sign_date: range, status: "approved")
    leaves.each do |leave|
      stat[leave.user_id][leave.leave_type] += leave.hours
    end
    return stat
  end
end
