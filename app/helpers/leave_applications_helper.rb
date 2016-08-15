module LeaveApplicationsHelper
  def convert_time_format(time_object, key = :default)
    time_object.to_s(key)
  end

  def set_default_time(time_object, key)
    return time_object if action_name == "edit"

    time_object = Time.zone.now
    if over? time_object, hour: 18
      time_object = time_object.change day: next_business_(:day, time_object), hour: 9, min: 30
    else
      if over? time_object, min:30
        time_object = time_object.change hour: next_business_(:hour, time_object), min: 0
      else
        time_object = time_object.change min: 30
      end
    end
    byebug
    (key==:end) ? (time_object = time_object.change hour: next_business_(:hour, time_object), min: 30) : time_object
  end

  def over?(time_object , options={})
    result = true
    options.each {|key, val| result = result && time_object.send(key).send(:>, val)}
    result
  end

  def next_business_(key, time_object)
    1.send("business_#{key.to_s}").after(time_object).send(key)
  end
end
