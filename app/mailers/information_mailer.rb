# frozen_string_literal: true

class InformationMailer < ApplicationMailer
  def new_application(leave_application)
    @leave_application = leave_application

    mail(
      to: Settings.mailer.admin_mails,
      subject: "New Leave Application about #{@leave_application.user.name}"
    )
  end

  def cancel_application(leave_application)
    @leave_application = leave_application

    mail(
      to: Settings.mailer.admin_mails,
      subject: "#{@leave_application.user.name} just canceled leave application"
    )
  end
end
