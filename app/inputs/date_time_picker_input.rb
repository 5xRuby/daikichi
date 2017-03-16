# frozen_string_literal: true
class DateTimePickerInput < SimpleForm::Inputs::Base
  def input
    template.content_tag(:div, class: 'row') do
      template.content_tag(:div, class: 'col-sm-5') do
        template.content_tag(:div, class: 'form-group') do
          template.content_tag(:div, class: 'input-group date', id: "datetimepicker_#{options[:time]}") do
            template.concat @builder.text_field(attribute_name, input_html_options)
            template.concat span_remove
          end
        end
      end
    end
  end

  def input_html_options
    super.merge(class: 'form-control', type: 'text')
  end

  def span_remove
    template.content_tag(:span, class: 'input-group-addon') do
      template.content_tag(:span, nil, class: 'glyphicon glyphicon-calendar')
    end
  end
end
