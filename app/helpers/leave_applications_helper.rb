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

  def need_deduct_salary?(header)
    header == 'personal' || header == 'halfpaid_sick'
  end
end
