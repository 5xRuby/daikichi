# frozen_string_literal: true
class Backend::LeaveApplicationsController < Backend::BaseController
  include Selectable

  def index
    @current_collection = collection_scope.with_year(specific_year)
    @current_collection = @current_collection.with_status(params[:status]) if status_selected?
    @current_collection = @current_collection.page(params[:page])
  end

  def verify
  end

  def update
    if current_object.update(resource_params)
      params[:approve] ? approve : reject
    else
      respond_to do |f|
        f.html { render action: :verify }
        f.json
      end
    end
  end

  def statistics
    @users = User.with_leave_application_statistics(specific_year, specific_month).all
  end

  private

  def approve
    if current_object.pending?
      current_object.approve!(current_user)
      action_success
    else
      action_fail t("warnings.not_verifiable"), :verify
    end
  end

  def reject
    if current_object.pending?
      current_object.reject!(current_user)
      action_success
    else
      action_fail t("warnings.not_verifiable"), :verify
    end
  end

  def collection_scope
    if params[:id]
      LeaveApplication
    else
      LeaveApplication.order(id: :desc)
    end
  end

  def resource_params
    params.require(:leave_application).permit(:comment)
  end

  def url_after(action)
    if @actions.include?(action)
      url_for(action: :index, controller: controller_path, params: { status: :pending })
    else
      request.env["HTTP_REFERER"]
    end
  end
end
