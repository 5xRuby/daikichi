class LeaveApplicationsController < BaseController
  def update
    if current_object.update(resource_params)
      current_object.revise!
      action_success
    else
      respond_to do |f|
        f.html { return render action: :edit }
        f.json
      end
    end
  end

  def cancel
    current_object.cancel!
    @actions << :cancel
    action_success
  end

  private

  def collection_scope
    current_user.leave_applications
  end

  def resource_params
    params.require(:leave_application).permit(
      :leave_type, :start_time, :end_time, :description
    )
  end
end
