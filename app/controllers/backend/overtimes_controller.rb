class Backend::OvertimesController < Backend::BaseController

  before_action :set_query_object, except: :statistics

  def index
    @users = User.all
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

  def add_leave_time
    @leave_time = LeaveTime.new
  end

  def create_leave_time
    params[:leave_time][:user_id] = current_object.user.id
    params[:leave_time][:overtime_id] = params[:id]
    @leave_time = LeaveTime.new(resource_params)
    if @leave_time.save(resource_params)
      action_success(verify_backend_overtime_path(current_object))
    else
      render :add_leave_time
    end
  end

  def add_compensatory_pay
    @overtime_pay = OvertimePay.new
  end

  def create_compensatory_pay
    params[:overtime_pay][:user_id] = current_object.user.id
    params[:overtime_pay][:overtime_id] = params[:id]
    @overtime_pay = OvertimePay.new(resource_params)
    if @overtime_pay.save(resource_params)
      action_success(verify_backend_overtime_path(current_object))
    else
      render :add_overtime_pay
    end
  end

  def statistics
    search_params = params.fetch(:q, {})&.permit(:year_eq, :month_eq)
    @q = Overtime.where(compensatory_type: 'pay', status: :approved).ransack(search_params)
    @summary = @q.result
  end

  private

  def resource_params
    case action_name
    when 'create' then params.require(:overtime).permit(:user_id, :hours, :start_time, :end_time, :description)
    when 'update' then params.require(:overtime).permit(:comment)
    when 'create_leave_time' then params.require(:leave_time).permit(:user_id, :overtime_id, :leave_type, :quota, :effective_date, :expiration_date, :remark)
    when 'create_compensatory_pay' then params.require(:overtime_pay).permit(:user_id, :overtime_id, :hour, :remark)
    end
  end

  def set_query_object
    @q = Overtime.ransack(search_params)
  end

  def search_params
    @search_params = params.fetch(:q, {})&.permit(
      :s, :status_eq, :end_time_lteq, :start_time_gteq, :compensatory_type_eq)
  end

  def collection_scope
    @q.result.preload(:user)
  end

  def approve
    if current_object.pending?
      current_object.approve!(current_user)
      action_success
    else
      action_fail t('warnings.not_verifiable'), :verify
    end
  end

  def reject
    if current_object.pending? or current_object.approved?
      current_object.reject!(current_user)
      action_success
    else
      action_fail t('warnings.not_verifiable'), :verify
    end
  end
end