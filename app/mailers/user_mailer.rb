class UserMailer < ApplicationMailer
  def reply_leave_applicaiton_email(leave_application)
    @leave_application = leave_application

    mail(
      to: @leave_application.user.email,
      subject: "<請假結果通知> 你的#{I18n.t(@leave_application.leave_type)}已被#{I18n.t(@leave_application.status)}."
    )
  end
end
