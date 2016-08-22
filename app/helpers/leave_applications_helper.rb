module LeaveApplicationsHelper
  def convert_time_format(time_object, key = :default)
    time_object.to_s(key)
  end

  def adjusted_time(key)
    time_object = Time.zone.now.change(hour: 9, min: 30)
    if key == :start
      time_object.change(hour: 9, min: 30)
    else
      time_object.change(hour: 10, min: 30)
    end
  end

  def date_time_picker_hash(key, time_object)
    {as: :date_time_picker, time: key.to_s, input_html: {value: time_object}, require: true}
  end

  def trans(value, scope)
    t("misc.#{scope}.#{value}")
  end
end
