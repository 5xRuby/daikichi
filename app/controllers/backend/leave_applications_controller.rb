# frozen_string_literal: true
class Backend::LeaveApplicationsController < Backend::BaseController

  def verify
  end

  def approve
    current_object.approve!(current_user)
    @actions << :approve
    action_success
  end

  def reject
    current_object.reject!(current_user)
    @actions << :reject
    action_success
  end

  private

  def collection_scope
    if params[:id]
      LeaveApplication
    else
      LeaveApplication.order(id: :desc)
    end
  end
end
