class LeaveApplicationsController < BaseController

  def create
    current_object = collection_scope.new(resource_params)
    return render action: :new unless current_object.save
    current_object.calculate_hours_and_deduct_it_from_leave_time
    action_success
  end

  def update
    if current_object.update(resource_params)
      current_object.calculate_hours_and_deduct_it_from_leave_time
      action_success
    else
      respond_to do |f|
        f.html { return render action: :edit }
        f.json
      end
    end
  end

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
