# frozen_string_literal: true
class Backend::LeaveTimesController < Backend::BaseController
  before_action :set_query_object

  def index
    @users = User.where.not(role: 'resigned')
  end

  def new
    @current_object = LeaveTime.new
  end

  def create
    @current_object = LeaveTime.new(resource_params)
    return render action: :new unless @current_object.save

    if request.env['HTTP_REFERER'].include?('leave_application_id')
      verify_id = request.env['HTTP_REFERER'].partition('=').last
      action_success(verify_backend_leave_application_path(verify_id))
    else
      action_success
    end
  end

  def append_quota
    @current_object = collection_scope.new(leave_time_params_by_leave_application)
    render :new
  end

  def batch_new
    @current_object = LeaveTime.new
  end

  def batch_create
    user_ids = params[:leave_time][:user_id]
    user_ids.each do |user_id|
      @current_object = LeaveTime.new(batch_leave_time_params.merge(user_id: user_id))
      return render action: :batch_new unless @current_object.save
    end
    action_success
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

  def batch_leave_time_params
    params.require(:leave_time).permit(
      :leave_type, :quota, :effective_date, :expiration_date, :usable_hours, :used_hours, :remark)
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
