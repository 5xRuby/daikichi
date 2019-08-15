# frozen_string_literal: true

class AnnualLeaveIndex < ActiveYaml::Base
  set_root_path Rails.root.join('config')
  set_filename self.name.underscore
end
