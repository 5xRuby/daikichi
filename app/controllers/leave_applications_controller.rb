# frozen_string_literal: true
class LeaveApplicationsController < BaseController
  def index
    if params[:status]
      @current_collection = collection_scope.where(status: params[:status]).page(params[:page])
    else
      @current_collection = collection_scope.page(params[:page])
    end
  end

  def update
    if !current_object.canceled? and current_object.update(resource_params)
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
    if current_object.canceled?
      action_fail t("warnings.not_cancellable"), :index
    else
      current_object.cancel!
      @actions << :cancel
      action_success
    end
  end

  private

  def collection_scope
    if params[:id]
      LeaveApplication.where(user_id: current_user.id)
    else
      LeaveApplication.where(user_id: current_user.id).order(id: :desc)
    end
  end

  def resource_params
    params.require(:leave_application).permit(
      :leave_type, :start_time, :end_time, :description
    )
  end

  def url_after(action)
    if @actions.include?(action)
      url_for(action: :index, status: :pending)
    else
      request.env["HTTP_REFERER"]
    end
  end
end
