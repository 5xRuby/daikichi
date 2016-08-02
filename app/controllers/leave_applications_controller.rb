class LeaveApplicationsController < BaseController

  def collection_scope
    if params[:id]
      current_user.leave_applications
    else
      current_user.leave_applications.order(id: :desc)
    end
  end

  private

  def resource_params
    params.require(:leave_application).permit(
      :leave_type, :start_time, :end_time, :description
    )
  end
end
