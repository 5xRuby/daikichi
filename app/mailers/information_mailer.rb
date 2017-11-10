class InformationMailer < ApplicationMailer
  def new_application(leave_application)
    @leave_application = leave_application
    mail(from: "hi@5xruby.tw", to: "hi@5xruby.tw", subject: 'New Leave Application')
  end

  def send_approve(leave_application)
    @leave_application = leave_application
    mail(from: "hi@5xruby.tw", to: @leave_application.user.email, subject: 'Your Leave Application is Approved.')
  end
end
