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

    config.enable_sign_in_as = (Rails.env != 'production' && ENV['ENABLE_LOGIN_AS'].to_i == 1)

    config.active_record.observers = %i(leave_application_observer)

    config.after_initialize do
      Rails.application.routes.default_url_options = { host: Settings.host }
    end
  end
end
