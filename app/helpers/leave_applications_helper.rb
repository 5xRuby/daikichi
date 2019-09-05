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
    return if leave_time.zero?

    %w(personal halfpaid_sick).include? leave_type
  end

  def summary_from(summary, user_id)
    leave_types = Settings.leave_times.quota_types.keys
    summary[user_id] || Hash[leave_types.collect { |type| [type, 0] }]
  end

  def leave_type_dropdown_menu(action_name, user)
    if user.role == 'contractor'
      LeaveApplication.enum_attributes_for_select(:leave_types, [:remote, :sick, :maternity, :marriage, :compassionate, :official, :occpational_sick, :menstrual])
    else
      LeaveApplication.enum_attributes_for_select(:leave_types)
    end
  end

  def link_to_attachment(attachment)
    link_to t('.exam_attachment'), current_object.attachment.url, target: :_blank, rel: 'noopener' if attachment
  end
end
