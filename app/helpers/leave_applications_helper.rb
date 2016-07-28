module LeaveApplicationsHelper
  def convert_time_format(time_object, key = :default)
    time_object.to_s(key)
  end
end
