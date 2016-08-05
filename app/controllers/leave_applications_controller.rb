class LeaveApplicationsController < BaseController

  def collection_scope
    current_user.leave_applications
  end

  private

  def resource_params
    params.require(:leave_application).permit(
      :leave_type, :start_time, :end_time, :description
    )
  end
end
