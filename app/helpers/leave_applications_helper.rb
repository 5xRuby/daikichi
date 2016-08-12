module LeaveApplicationsHelper
  def convert_time_format(time_object, key = :default)
    time_object.to_s(key)
  end

  def new_input_hash(key, time_object = Time.zone.now)
    if key==:start
      time_object = time_object.change hour: 9, min: 30
    else
      time_object = time_object.change hour: 10, min: 30
    end
    hash(key, time_object)
  end

  def edit_input_hash(key, time_object)
    hash(key, time_object)
  end

  def hash(key, time_object)
    {as: :date_time_picker, time: key.to_s, input_html: {value: time_object}, require: true}
  end
end
