class DateTimePickerStartInput < SimpleForm::Inputs::Base
  def input
    template.content_tag(:div, class: 'row') do
      template.content_tag(:div, class: 'col-sm-5') do
        template.content_tag(:div, class: 'form-group') do
          template.content_tag(:div, class: 'input-group date', id: 'datetimepicker_start') do
            template.concat @builder.text_field(attribute_name, input_html_options)
            template.concat span_remove
          end
        end
      end
    end
  end

  def input_html_options
    super.merge({class: 'form-control', type: 'text'})
  end

  def span_remove
    template.content_tag(:span, class: 'input-group-addon') do
      template.concat icon_remove
    end
  end

  def icon_remove
    "<span class='glyphicon glyphicon-calendar'></span>".html_safe
  end

end

