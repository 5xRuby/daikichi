# frozen_string_literal: true

class RemoteController < BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource class: LeaveApplication

  def create
    @current_object = collection_scope.new(resource_params)
    if @current_object.save
      action_success
    else
      render action: :new
    end
  end

  private

  def collection_scope
    current_user.leave_applications.where(leave_type: :remote)
  end

  def resource_params
    params.require(:remote_application).permit(
      :start_time, :end_time, :description
    )
  end

  def url_after(action)
    if @actions.include?(action)
      url_for(controller: :leave_applications, action: :index)
    else
      request.env['HTTP_REFERER']
    end
  end
end
