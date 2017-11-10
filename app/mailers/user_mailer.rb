class UserMailer < ApplicationMailer
  def reply_leave_applicaiton_email(leave_application)
    @leave_application = leave_application

    mail(
      to: @leave_application.user.email,
      subject: "Your Leave Application Status is #{@leave_application.status}."
    )
  end
end
