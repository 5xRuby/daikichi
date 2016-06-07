module ApplicationHelper
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
