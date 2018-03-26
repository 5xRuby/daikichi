class InformationMailer < ApplicationMailer
  ADMIN_EMAIL_LISTS = [
    'hi@5xruby.tw'
  ].freeze

  DEVELOP_EMAIL_LISTS = [
    'eileen@5xruby.tw'
  ].freeze

  def new_application(leave_application)
    @leave_application = leave_application

    mail(
      to: receiver_lists,
      subject: "New Leave Application about #{@leave_application.user.name}"
    )
  end

  def cancel_application(leave_application)
    @leave_application = leave_application

    mail(
      to: receiver_lists,
      subject: "#{@leave_application.user.name} just canceled leave application"
    )
  end

  private

  def receiver_lists
    Rails.env.production? ? ADMIN_EMAIL_LISTS : DEVELOP_EMAIL_LISTS
  end
end
