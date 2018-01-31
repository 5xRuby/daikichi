# frozen_string_literal: true
class LeaveApplicationsController < BaseController
  include Selectable
  before_action :set_query_object
  after_action :auto_approve_for_contractor, only: [:create, :update], if: :contractor?

  def index
    @current_collection = collection_scope.page(params[:page])
    @current_collection = Kaminari.paginate_array(@current_collection.first(5)).page(params[:page]) unless query?
    @current_collection = @current_collection.with_status(params[:status]) if status_selected?
  end

  def create
    @current_object = collection_scope.new(resource_params)
    if @current_object.save
      action_success
    else
      render action: :new
    end
  end

  def update
    if current_object.canceled?
      action_fail t('warnings.not_cancellable'), :edit
    else
      current_object.assign_attributes(resource_params)
      if !current_object.changed?
        action_fail t('warnings.no_change'), :edit
      elsif current_object.revise!
        action_success
      else
        render action: :edit
      end
    end
  end

  def cancel
    if current_object.may_cancel?
      current_object.cancel!
      @actions << :cancel
      action_success
    elsif current_object.approved?
      action_fail t('warnings.already_happened'), :index
    else
      action_fail t('warnings.not_cancellable'), :index
    end
  end

  private

  def collection_scope
    if params[:id]
      current_user.leave_applications
    else
      @q.result.where(user_id: current_user.id).order(id: :desc).page(params[:page])
    end
  end

  def query?
    !params[:q].nil?
  end

  def search_params
    @search_params = params.fetch(:q, {})&.permit(
      :s, :leave_type_eq, :status_eq, :end_date_gteq, :start_date_lteq)
  end

  def set_query_object
    @q = current_user.leave_applications.ransack(search_params)
  end

  def resource_params
    params.require(:leave_application).permit(
      :leave_type, :start_time, :end_time, :description
    )
  end

  def url_after(action)
    if @actions.include?(action)
      url_for(action: :index, controller: controller_path)
    else
      request.env['HTTP_REFERER']
    end
  end

  def auto_approve_for_contractor
    current_object.approve!(current_user)
  end

  def contractor?
    current_user.contractor?
  end
end
