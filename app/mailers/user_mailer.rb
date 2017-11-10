class UserMailer < ApplicationMailer
  def reply_leave_applicaiton_email(leave_application)
    @leave_application = leave_application
    mail(from: "hi@5xruby.tw", to: @leave_application.user.email, subject: 'Your Leave Application Status is Changed.')
  end
end
