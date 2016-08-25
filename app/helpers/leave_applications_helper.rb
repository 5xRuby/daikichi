module LeaveApplicationsHelper
  def convert_time_format(time_object, key = :default)
    time_object.to_s(key)
  end

  def time_object_by_hour_min(hour, min)
    Time.zone.now.change(hour: hour, min: min)
  end

  def date_time_picker_hash(key, time_object)
    {as: :date_time_picker, time: key.to_s, input_html: {value: time_object}, require: true}
  end

  def trans(value, scope)
    t("misc.#{scope}.#{value}")
  end
end
