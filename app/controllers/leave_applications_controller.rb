class LeaveApplicationsController < BaseController

  def collection_scope
    if params[:id]
      LeaveApplication
    else
      LeaveApplication.is_manager?(current_user).order(id: :desc)
    end
  end

  private

  def resource_params
    params.require(:leave_application).permit(
      :leave_type, :start_time, :end_time, :description
    ).merge(user_id: current_user.id)
  end
end
