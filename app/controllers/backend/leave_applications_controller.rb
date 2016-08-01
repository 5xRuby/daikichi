class Backend::LeaveApplicationsController < Backend::BaseController

  def collection_scope
    if params[:id]
      LeaveApplication
    else
      LeaveApplication.is_manager().order(id: :desc)
    end
  end

  private

  def resource_params
   # to fill
  end
end
