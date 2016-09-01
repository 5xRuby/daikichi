class LeaveApplicationsController < BaseController
  def index
    if params[:status]
      @current_collection = LeaveApplication.where(status: params[:status]).page(params[:page])
    end
  end

  def update
    if not current_object.canceled? and current_object.update(resource_params)
      current_object.revise!
      action_success
    elsif current_object.canceled?
      action_fail t("warnings.not_cancellable"), :edit
    else
      respond_to do |f|
        f.html { return render action: :edit }
        f.json
      end
    end
  end

  def cancel
    unless current_object.canceled?
      current_object.cancel!
      @actions << :cancel
      action_success
    else
      action_fail t("warnings.not_cancellable"), :index
    end
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
