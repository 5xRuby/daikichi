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
    la_start_date = @leave_application.start_time.to_date
    la_end_date   = @leave_application.end_time.to_date
    lhs_by_date   = leave_hours_by_date

    # 檢查 leave_times 至少有切到 leave_application 之起點以及終點
    include_start_time = include_end_time = false
    lts.each do |lt|
      include_start_time = true if lt.cover?(la_start_date)
      include_end_time   = true if lt.cover?(la_end_date)
    end
    
    # 如果確定起點或結束時間沒有切到 leave_time 則回傳 false
    return false unless include_start_time && include_end_time

    lt_usages = []
    locked_hours = []

    # 迭代 leave_times 並且開始扣除 leave_hours_by_date 之額度
    lts.each do |lt|
      lt_used_hour_count = 0
      start_date = la_start_date > lt.effective_date  ? la_start_date : lt.effective_date
      end_date   = la_end_date   < lt.expiration_date ? la_end_date   : lt.expiration_date

      start_date.upto(end_date) do |date|
        # 如果假單對應之日期之時間已經扣為 0，則跳至下一天
        unless lhs_by_date[date].zero?
          if lt_used_hour_count + lhs_by_date[date] <= lt.usable_hours
            # leave_time 如果夠使用則填補所有當日時數
            lt_used_hour_count += lhs_by_date[date]
            lhs_by_date[date] = 0
          else
            # leave_time usable_hours 不夠使用，直接跳出並紀錄新的 leave_time_usage
            remain_hours = lt_used_hour_count + lhs_by_date[date] - lt.usable_hours
            lt_used_hour_count = lt.usable_hours
            lhs_by_date[date] = remain_hours
            break
          end
        end
      end

      lt_usages.push({ leave_time: lt, used_hours: lt_used_hour_count })
    end

    # 檢查 leave_hours_by_date 是否還有殘餘的時數 
    lhs_by_date.each_value do |v|
      return false unless v.zero?
    end

    lt_usages.each do |lt_usage|
      # Create LeaveTimeUsage Record
      leave_time_usage = @leave_application.leave_time_usages.new
      leave_time_usage.leave_time = lt_usage[:leave_time]
      leave_time_usage.used_hours = lt_usage[:used_hours]
      leave_time_usage.save!

      # Update leave_time locked hours
      lt_usage[:leave_time].lock_hours lt_usage[:used_hours]
    end
    true
  end

  private

  def work_periods_by_date
    work_periods.group_by { |wp| wp.start_time.localtime.to_date }
  end

  def work_periods
    $biz.periods.after(@leave_application.start_time).timeline
      .until(@leave_application.end_time).to_a
  end
end
