class UserMailerPreview < ActionMailer::Preview
  def reply_leave_applicaiton_email
    test_leave_application = LeaveApplication.last
    UserMailer.reply_leave_applicaiton_email(test_leave_application)
  end
end