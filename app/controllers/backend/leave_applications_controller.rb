class Backend::LeaveApplicationsController < Backend::BaseController
  def verify
  end

  def approve
    current_object.approve!(current_user)
    action_success
  end

  def reject
    current_object.reject!(current_user)
    action_success
  end

  private

  def url_after_approve
    url_for(action: :index)
  end

  alias url_after_reject url_after_approve
  alias url_after_revise url_after_approve
  alias url_after_close url_after_approve

  def collection_scope
    if params[:id]
      LeaveApplication
    else
      LeaveApplication.order(id: :desc)
    end
  end

end
