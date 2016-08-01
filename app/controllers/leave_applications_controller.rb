class LeaveApplicationsController < BaseController

  def collection_scope
    if params[:id]
      LeaveApplication
    else
      LeaveApplication.get_scope(current_user)
    end
  end

  private

  def resource_params
    params.require(:leave_application).permit(
      :leave_type, :start_time, :end_time, :description
    ).merge(user_id: current_user.id)
  end
end
