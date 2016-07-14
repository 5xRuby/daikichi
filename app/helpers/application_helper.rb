module ApplicationHelper
  def tr_by_object(attribute, object = current_object, is_option = false)
    content_tag :tr do
      concat content_tag :th, t("#{t_attributes}.#{object.model_name.param_key}.#{attribute}")
      concat content_tag :td, td_value_by_object(object, attribute, is_option)
    end
  end

  def td_value_by_object(object, attribute, is_option)
    if is_option
      t("#{t_options}.#{object.model_name.param_key}.#{attribute}.#{object[attribute]}")
    else
      object[attribute]
    end
  end

  def t_attributes
    "activerecord.attributes"
  end

  def t_options
    "simple_form.options"
  end

  def dropdown_title(label = '')
    capture_haml do
      haml_tag 'a.dropdown-toggle', {'data-toggle': 'dropdown', 
                                     'role': 'button', 
                                     'aria-haspopup': true,
                                     'aria-expanded': 'false'} do
        haml_concat label
        haml_tag 'span.caret'
      end
    end
  end

  def no_data_alert(message = t('warnings.no_data'))
    content_tag :div, message, class: 'alert alert-warning'
  end

end
