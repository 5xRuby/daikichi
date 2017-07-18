class FlowdockService
  include ActiveModel::Model
  include Rails.application.routes.url_helpers

  attr_accessor :leave_application

  def initialize(attributes={})
    super
    @flow_token_client = Flowdock::Client.new(flow_token: Settings.flowdock.token)
  end

  def send_create_notification
    notify(
      subject: "#{leave_application.user.name} 新增了一筆 #{LeaveApplication.human_enum_value(:leave_type, leave_application.leave_type)} 假單",
      content: (LeaveApplicationsController.render partial: 'leave_applications/notification', locals: { leave_application: leave_application }),
      url: verify_backend_leave_application_url(id: leave_application),
      color: "green",
      value: "Create",
      thread_id: leave_application.id
    )
  end

  def send_update_notification(event)
    return if event.blank?
    executer = %i[canceled pending].include?(event) ? leave_application.user : leave_application.manager
    notify(
      subject: "#{executer.name} #{LeaveApplication.human_enum_value(:modify_actions, event)}了一筆 #{leave_application.user.name} 的 #{LeaveApplication.human_enum_value(:leave_type, leave_application.leave_type)} 假單",
      content: (LeaveApplicationsController.render partial: 'leave_applications/notification', locals: { leave_application: leave_application }),
      url: verify_backend_leave_application_url(id: leave_application),
      color: "yellow",
      value: "Update",
      thread_id: leave_application.id
    )
  end

  private

  def notify(subject: , content: , url: , color: , value: , thread_id:)
    @flow_token_client.post_to_thread(
    event: "activity",
    author: {
        name: "Daikichi",
        avatar: "http://i.imgur.com/ycz7jqg.png",
    },
    title: "5xRuby",
    external_thread_id: thread_id,
    thread: {
        title: subject,
        body: content,
        external_url: url,
        status: {
            color: color,
            value: value
        }
      }
    )
  end  
end