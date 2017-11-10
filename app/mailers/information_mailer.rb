class InformationMailer < ApplicationMailer
  @@hi_5xruby = "hi@5xruby.tw"

  def new_application(leave_application)
    @leave_application = leave_application
    mail(from: @@hi_5xruby, to: @@hi_5xruby, subject: 'New Leave Application')
  end
end
