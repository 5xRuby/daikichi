class InformationMailer < ApplicationMailer

  ADMIN_EMAIL_LISTS = [
    "hi@5xruby.tw",
  ]

  DEVELOP_EMAIL_LISTS = [
    "eileen@5xruby.tw",
  ]

  def new_application(leave_application)
    @leave_application = leave_application

    mail(
      to: receiver_lists,
      subject: "New Leave Application about #{@leave_application.user.name}"
    )
  end

  private

  def receiver_lists
    Rails.env.production? ? ADMIN_EMAIL_LISTS : DEVELOP_EMAIL_LISTS
  end

end
