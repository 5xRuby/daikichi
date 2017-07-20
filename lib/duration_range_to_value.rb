# frozen_string_literal: true
class DurationRangeToValue
  # duration ranges_strs example:
  # ["~ 1.day : 1.day", "2.days ~ 5.days : 1.week", "6.days ~ 10.days : 1.month", "10.days ~ : 2.months"]
  def initialize(ranges_strs)
    @ranges = ranges_strs.map do |pair_str|
      range_str, value_str = pair_str.split ':'
      range_start, range_end = range_str.split('~').map do |r|
        r = eval r
        r.instance_of?(ActiveSupport::Duration) ? r.to_i : nil
      end
      [range_start, range_end, eval(value_str)]
    end
  end

  def get_from_duration_num(duration_num)
    found_at = @ranges.index do |pair|
      (pair[0].present? ? (duration_num >= pair[0]) : true) &&
        (pair[1].present? ? (duration_num <= pair[1]) : true)
    end
    found_at.nil? ? nil : @ranges[found_at][2]
  end

  def get_from_duration(duration)
    get_from_duration_num(duration.to_i)
  end

  def get_from_past_time(time)
    get_from_duration_num(Time.current - time)
  end

  def get_from_time_diff(time1, time2)
    get_from_duration_num(time1 > time2 ? time1 - time2 : time2 - time1)
  end
end
