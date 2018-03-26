class InformationMailerPreview < ActionMailer::Preview
  def new_application
    test_leave_application = LeaveApplication.last
    InformationMailer.new_application(test_leave_application)
  end
end
