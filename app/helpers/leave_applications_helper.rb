# frozen_string_literal: true
module LeaveApplicationsHelper
  def time_object_by_hour_min(hour, min)
    Time.zone.now.change(hour: hour, min: min)
  end

  def date_time_picker_hash(key, time_object)
    { as: :date_time_picker, time: key.to_s, input_html: { value: time_object }, require: true }
  end

  def colored_state_label(status)
    humanize_status = LeaveApplication.human_enum_value(:statuses, status)
    case status.to_sym
    when :pending
      haml_tag :span, humanize_status, class: 'label label-primary'
    when :canceled
      haml_tag :span, humanize_status, class: 'label label-default'
    when :approved
      haml_tag :span, humanize_status, class: 'label label-success'
    when :rejected
      haml_tag :span, humanize_status, class: 'label label-danger'
    else
      haml_tag :span, humanize_status, class: 'label label-danger'
    end
  end

  def need_deduct_salary?(leave_type, leave_time)
    return if leave_time == 0
    leave_type == 'personal' || leave_type == 'halfpaid_sick'
  end

  def sum_leave_hours(user_id, year, month)
    leave_types = Settings.leave_times.quota_types.keys
    leave_times_lists = Hash[leave_types.collect{ |type| [type, 0]}]
    total_leave_times = LeaveApplication.where(user_id: user_id).leave_within_range((Time.zone.local(year,month,1).beginning_of_month),(Time.zone.local(year,month,1).end_of_month)).includes(:leave_time_usages, :leave_times).map(&:leave_time_usages).flatten.group_by{|usage| usage.leave_time.leave_type }.map{|k,v|[k, v.map(&:used_hours).sum]}
    leave_times_lists.update Hash[total_leave_times]
  end
end
