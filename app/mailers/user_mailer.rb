# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def reply_leave_applicaiton_email(leave_application)
    @leave_application = leave_application
    if %w(staging development).include?(Rails.env)
      mail(
        to: @leave_application.user.email,
        subject: "[測試信]<請假結果通知> 你的#{LeaveApplication.human_enum_value(:leave_type, @leave_application.leave_type)}已被#{LeaveApplication.human_enum_value(:status, @leave_application.status)}"
      )
    else
      mail(
        to: @leave_application.user.email,
        subject: "<請假結果通知> 你的#{LeaveApplication.human_enum_value(:leave_type, @leave_application.leave_type)}已被#{LeaveApplication.human_enum_value(:status, @leave_application.status)}"
      )
    end
  end
end
