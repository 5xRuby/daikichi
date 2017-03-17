# frozen_string_literal: true
module ApplicationHelper
  # show 才會用到 tr_by_object，將 object 寫在最後面，可以在呼叫 tr_by_object 時省略不寫
  def tr_by_object(attribute, conversion = nil, key = nil, object = current_object)
    content_tag :tr do
      concat content_tag :th, t_attribute(attribute, object), class: 'col-md-3'
      concat content_tag :td, t_value(attribute, object, conversion, key), class: 'col-md-9'
    end
  end

  def t_attribute(attribute, object)
    t(attribute, scope: t_attribute_scope(object))
  end

  def t_attribute_scope(object)
    "activerecord.attributes.#{object.model_name.param_key}"
  end

  # t_value 可能在 index 裡直接被呼叫，把 object 寫在第二個參數比較方便
  def t_value(attribute, object, conversion = nil, key = nil)
    value = object.send(attribute)
    if value.nil? or conversion.nil?
      object.send(attribute)
    else
      self.send(conversion, object.send(attribute), attribute, object, key)
    end
  end

  # 轉換類的 function，view template 不要直接引用，請透過 t_value
  # ------------------------------文字轉換------------------------------
  def translate_text_value(text_value, attribute, object, key = nil)
    t(text_value, scope: text_value_translation_scope(attribute, object))
  end

  def text_value_translation_scope(attribute, object)
    "simple_form.options.#{object.model_name.param_key}.#{attribute}"
  end
  # --------------------------------------------------------------------

  # ------------------------------時間轉換------------------------------
  def convert_time_value(time_value, attribute, object, key = nil)
    time_value.to_formatted_s(key)
  end
  # --------------------------------------------------------------------

  # --------------------------User_object 轉換--------------------------
  def convert_user_object_to_name(user_object, attribute, object, key)
    user_object.send(key)
  end
  # --------------------------------------------------------------------

  def dropdown_title(label = '')
    capture_haml do
      haml_tag 'a.dropdown-toggle', dropdown_hash do
        haml_concat label
        haml_tag 'span.caret'
      end
    end
  end

  def dropdown_hash
    { "data-toggle": 'dropdown',
      "role": 'button',
      "aria-haspopup": 'true',
      "aria-expanded": 'false' }
  end

  def no_data_alert(message = t('warnings.no_data'))
    content_tag :div, message, class: 'alert alert-warning'
  end

  def status_select_option
    ([:all] + LeaveApplication::STATUS).map { |type| [I18n.t("simple_form.options.leave_application.status.#{type}"), type] }.to_h
  end

  def specific_year
    params[:year] || Time.now.year
  end

  def specific_month
    params[:month] || Time.now.month
  end

  def hours_to_humanize(hours)
    return '-' if hours == 0
    I18n.t('time.humanize_working_hour', days: hours.to_i / 8, hours: hours % 8, total: hours)
  end

  def type_selector(name, label, options, default)
    render 'shared/type_selector', name: name, label: label, options: options, default: default
  end

  def leave_times_table(leave_times, exclude_columns, &tools)
    render 'shared/leave_times_table',
           leave_times: leave_times,
           show_leave_type: !exclude_columns.include?(:leave_type),
           columns: [:name, :quota, :usable_hours_if_allow, :used_hours_if_allow, :effective_date, :expiration_date] - exclude_columns,
           tools: tools
  end
end
