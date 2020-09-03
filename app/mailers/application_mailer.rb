# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Settings.mailer.default_from

  layout 'mailer'
  prepend_view_path Rails.root.join('app', 'views', 'mailers')
end
