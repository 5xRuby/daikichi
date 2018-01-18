# frozen_string_literal: true
class BaseController < ApplicationController
  before_action :set_actions
  helper_method :current_collection, :current_object

  load_and_authorize_resource
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  def index; end

  def show; end

  def new
    @current_object = collection_scope.new(new_resource_params)
  end

  def create
    @current_object = collection_scope.new(resource_params)
    return render action: :new unless @current_object.save
    action_success
  end

  def destroy
    current_object.destroy
    action_success
  end

  def edit; end

  def update
    if current_object.update(resource_params)
      action_success
    else
      respond_to do |f|
        f.html { return render action: :edit }
        f.json
      end
    end
  end

  private

  def action_fail(message, action)
    flash[:alert] = message
    redirect_to action: action
  end

  def set_actions
    @actions = [:create, :update, :destroy, :batch_create]
  end

  def action_success(url = nil)
    respond_to do |f|
      f.html do
        flash[:success] ||= t("success.#{action_name}")
        redirect_to url || url_after(action_name.to_sym)
      end
      f.json
    end
  end

  # TODO: Seems never used in applications
  # override in controller if needed
  def require_permission
    check_permission current_object.employee
  end

  def check_permission(object_owner)
    return if current_employee == object_owner
    flash[:alert] = t('warnings.not_authorized')
    redirect_to root_path
  end

  def url_after(action)
    if @actions.include?(action)
      url_for(action: :index)
    else
      request.env['HTTP_REFERER']
    end
  end

  # You should implement these in your controller
  def collection_scope; end

  def resource_params; end

  def new_resource_params; end

  def current_collection
    @current_collection ||= collection_scope.page(params[:page])
  end

  def current_object
    @current_object ||= collection_scope.find(params[:id])
  end

  def specific_year
    params[:year] || Time.current.year
  end

  def specific_month
    params[:month] || Time.current.month
  end

  def specific_role
    params[:role] || %w(employee parttime)
  end
end
