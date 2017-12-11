# frozen_string_literal: true
class Backend::LeaveApplicationsController < Backend::BaseController
  include Selectable
  before_action :set_query_object

  def index
    @users = User.all
  end

  def create
    @current_object = collection_scope.new(resource_params)
    if @current_object.save
      @current_object.approve!(current_user)
      action_success
    else
      render action: :new
    end
  end

  def verify; end

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
  end

  private

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

  def collection_scope
    if params[:id]
      LeaveApplication
    else
      @q.result.preload(:user)
    end
  end

  def resource_params
    case action_name
    when "create" then params.require(:leave_application).permit(:user_id, :leave_type, :start_time, :end_time, :description, :comment)
    when "update" then params.require(:leave_application).permit(:comment)
    end
  end

  def search_params
    @search_params = params.fetch(:q, {})&.permit(
      :s, :leave_type_eq, :user_id_eq, :status_eq, :end_date_gteq, :start_date_lteq)
    @search_params.present? ? @search_params : @search_params.merge(status_eq: :pending)
  end

  def set_query_object
    @q = LeaveApplication.ransack(search_params)
  end

  def url_after(action)
    if @actions.include?(action)
      url_for(action: :index, controller: controller_path, params: { status: :pending })
    else
      request.env['HTTP_REFERER']
    end
  end
end
