# frozen_string_literal: true

Rails.application.configure do
  config.action_mailer.default_url_options = {
    host: ENV['MAIL_HOST'] || Settings.mailer.url_host
  }
end
