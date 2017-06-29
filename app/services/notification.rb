class Notification
  include ActiveModel::Model
  include Rails.application.routes.url_helpers

  attr_accessor :leave_application

  def initialize(attributes={})
    super
    @flow = Flowdock::Flow.new(
      api_token: Settings.api_token, 
      source: "Daichiki", 
      from: { name: "Daichiki", address: "hi@5xruby.tw"}
    )
  end

  def send_create_notification
    send_notification(
      subject: "#{leave_application.user.name} 新增了一筆 #{LeaveApplication.human_enum_value(:leave_type, leave_application.leave_type)} 假單",
      content: (LeaveApplicationsController.render partial: 'leave_applications/notification', locals: { leave_application: leave_application }),
      url: verify_backend_leave_application_url(id: leave_application)
    )
  end

  def send_revise_notification
    send_notification(
      subject: "#{leave_application.user.name} 修改了一筆 #{LeaveApplication.human_enum_value(:leave_type, leave_application.leave_type)} 假單",
      content: (LeaveApplicationsController.render partial: 'leave_applications/notification', locals: { leave_application: leave_application }),
      url: verify_backend_leave_application_url(id: leave_application)
    )
  end

  def send_approve_notification
    send_notification(
      subject: "#{leave_application.manager.name} 核准了一筆 #{leave_application.user.name} 的 #{LeaveApplication.human_enum_value(:leave_type, leave_application.leave_type)} 假單",
      content: (LeaveApplicationsController.render partial: 'leave_applications/notification', locals: { leave_application: leave_application }),
      url: verify_backend_leave_application_url(id: leave_application)
    )
  end

  def send_reject_notification
    send_notification(
      subject: "#{leave_application.manager.name} 駁回了一筆 #{leave_application.user.name} 的 #{LeaveApplication.human_enum_value(:leave_type, leave_application.leave_type)} 假單",
      content: (LeaveApplicationsController.render partial: 'leave_applications/notification', locals: { leave_application: leave_application }),
      url: verify_backend_leave_application_url(id: leave_application)
    )
  end

  def send_cancel_notification
    send_notification(
      subject: "#{leave_application.user.name} 取消了一筆 #{LeaveApplication.human_enum_value(:leave_type, leave_application.leave_type)} 假單",
      content: (LeaveApplicationsController.render partial: 'leave_applications/notification', locals: { leave_application: leave_application }),
      url: verify_backend_leave_application_url(id: leave_application)
    )
  end



  private
  def send_notification(subject:, content:, url:)
    @flow.push_to_team_inbox(
      subject: subject, 
      content: content, 
      link: url
    )
  end

  def hours_to_humanize(hours)
    return '-' if hours.to_i.zero?
    I18n.t('time.humanize_working_hour', days: hours.to_i / 8, hours: hours % 8, total: hours)
  end
end

