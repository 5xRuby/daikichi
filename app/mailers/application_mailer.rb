# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: 'hi@5xruby.tw'

  layout 'mailer'
  prepend_view_path Rails.root.join('app', 'views', 'mailers')
end
