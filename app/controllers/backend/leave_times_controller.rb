# frozen_string_literal: true
class Backend::LeaveTimesController < Backend::BaseController
  before_action :set_query_object

  def index
    @users = User.all
  end

  def append_quota
    @current_object = collection_scope.new(leave_time_params_by_leave_application)
    render :new
  end

  private

  def leave_time_params_by_leave_application
    leave_application = LeaveApplication.find(params[:leave_application_id])
    leave_application.leave_time_params
  end

  def set_query_object
    @q = LeaveTime.ransack(search_params)
  end

  def collection_scope
    if params[:id]
      LeaveTime.preload(:user, leave_time_usages: :leave_application)
    else
      @q.result.preload(:user)
    end
  end

  def resource_params
    params.require(:leave_time).permit(
      :user_id, :leave_type, :quota, :effective_date, :expiration_date, :usable_hours, :used_hours, :remark
    )
  end

  def search_params
    params.fetch(:q, {})&.permit(:s, :leave_type_eq, :effective_true, :user_id_eq)
  end

  def url_after(action)
    if @actions.include?(action)
      url_for(action: :index)
    else
      request.env['HTTP_REFERER']
    end
  end
end
