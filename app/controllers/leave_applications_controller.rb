class LeaveApplicationsController < BaseController
  def index
  end

  def show
    @leave_application = LeaveApplication.find(params[:id])
  end

  def collection_scope
    if params[:id]
      LeaveApplication
    else
      LeaveApplication.order(id: :asc)
    end
  end

  private

  def resource_params
    params.require(:leave_application).permit(
      :leave_type, :start_time, :end_time, :description
    )
  end
end
