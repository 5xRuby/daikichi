require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Daikichi
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Taipei'
    config.i18n.default_locale = 'zh-TW'
    config.autoload_paths << Rails.root.join('lib')

    config.active_record.observers = :leave_application_observer
  end
end
