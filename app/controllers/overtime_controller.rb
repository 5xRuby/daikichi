class OvertimeController < BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource class: LeaveApplication

  def create
    byebug
    @current_object = collection_scope.new(resource_params)
    if @current_object.save
      action_success
    else
      render action: :new
    end
  end

  private

  def collection_scope
    current_user.overtimes
  end

  def resource_params
    params.require(:overtime_application).permit(
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

