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
end
