# frozen_string_literal: true
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.human_enum_value(enum_name, enum_value)
    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
  end

  def self.enum_attributes_for_select(enum_name, except = [])
    self.send(enum_name).reject { |x| except.include?(x.to_sym) }.map do |enum_value, _|
      [I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name}.#{enum_value}"), enum_value]
    end
  end
end
