class AnnualLeaveIndex < ActiveYaml::Base
  set_root_path "#{Rails.root.to_s}/config"
  set_filename self.name.underscore
end
