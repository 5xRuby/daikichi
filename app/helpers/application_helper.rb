# ApplicationHelper
module ApplicationHelper
  def tr_by_object(attribute, object = current_object, key = nil)
    content_tag :tr do
      concat content_tag :th, t_attribute(attribute, object)
      concat content_tag :td, t_value(attribute, object, key)
    end
  end

  def t_attribute(attribute, object = current_object)
    t(attribute, scope: t_attribute_scope(object))
  end

  def t_value(attribute, object = current_object, key = nil)
    if key.nil?
      object[attribute]
    else
      t(key, scope: t_options_scope(object, attribute))
    end
  end

  def t_attribute_scope(object)
    "activerecord.attributes.#{object.model_name.param_key}"
  end

  def t_options_scope(object, attribute)
    "simple_form.options.#{object.model_name.param_key}.#{attribute}"
  end

  def dropdown_title(label = '')
    capture_haml do
      haml_tag 'a.dropdown-toggle', {'data-toggle': 'dropdown', 
                                     'role': 'button', 
                                     'aria-haspopup': 'true',
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
