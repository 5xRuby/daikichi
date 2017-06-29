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

  def send_update_notification(event)
    executer = %i[canceled pending].include?(event) ? leave_application.user : leave_application.manager
    send_notification(
      subject: "#{executer.name} #{LeaveApplication.human_enum_value(:modify_actions, event)}了一筆 #{leave_application.user.name} 的 #{LeaveApplication.human_enum_value(:leave_type, leave_application.leave_type)} 假單",
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
end

