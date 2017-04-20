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
    # 如果確定起點或結束時間沒有切到 leave_time 則回傳 false
    return false unless leave_time_include_application_time_interval

    # 迭代 leave_times 並且開始扣除 leave_hours_by_date 之額度
    @available_leave_times.each do |lt|
      lt_used_hour_count = 0
      
      iterate_leave_time_dates(lt) do |date|
        # 如果假單對應之日期之時間已經扣為 0，則跳至下一天
        next if corresponding_leave_hours_date_is_zero?(date)
        if lt_used_hour_count + @leave_hours_by_date[date] <= lt.usable_hours
          # leave_time 如果夠使用則填補所有當日時數
          lt_used_hour_count += @leave_hours_by_date[date]
          @leave_hours_by_date[date] = 0
        else
          # leave_time usable_hours 不夠使用，直接跳出並紀錄新的 leave_time_usage
          remain_hours = lt_used_hour_count + @leave_hours_by_date[date] - lt.usable_hours
          lt_used_hour_count = lt.usable_hours
          @leave_hours_by_date[date] = remain_hours
          break
        end
      end

      @leave_time_usages.push({ leave_time: lt, used_hours: lt_used_hour_count })
    end

    # 檢查 leave_hours_by_date 是否還有殘餘的時數
    return false if remain_leave_hours_by_date?
    
    # 產生 LeaveTimeUsage 以及相對應的 LeaveTime locked_hours
    create_leave_time_usage_and_lock_hours
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

  # 檢查 leave_times 至少有切到 leave_application 之起點以及終點
  def leave_time_include_application_time_interval
    include_start_time = include_end_time = false
    @available_leave_times.each do |lt|
      include_start_time = true if lt.cover?(@leave_application.start_time.to_date)
      include_end_time   = true if lt.cover?(@leave_application.end_time.to_date)
    end
    include_start_time && include_end_time
  end

  def iterate_leave_time_dates(leave_time)
    la_start_date = @leave_application.start_time.to_date
    la_end_date   = @leave_application.end_time.to_date
    start_date = la_start_date > leave_time.effective_date  ? la_start_date : leave_time.effective_date
    end_date   = la_end_date   < leave_time.expiration_date ? la_end_date   : leave_time.expiration_date
    start_date.upto(end_date) { |date| yield date }
  end

  def corresponding_leave_hours_date_is_zero?(date)
    @leave_hours_by_date[date].zero?
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
