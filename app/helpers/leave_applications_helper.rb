module LeaveApplicationsHelper

  def time_object_by_hour_min(hour, min)
    Time.zone.now.change(hour: hour, min: min)
  end

  def date_time_picker_hash(key, time_object)
    {as: :date_time_picker, time: key.to_s, input_html: {value: time_object}, require: true}
  end
end
