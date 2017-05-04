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

  def build_leave_time_usages
    lts = @leave_application.available_leave_times
    lhs_by_date = leave_hours_by_date

    # 檢查 leave_times 至少有切到 leave_application 之起點以及終點

    # 迭代 leave_times 並且開始扣除 leave_hours_by_date 之額度
    # - 當扣除到額度時，產生 leave_time_usage 記錄
    # - 當扣除到額度時，將相對應扣除之時數記錄到 leave_times 的 locked_hours
  
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
