# BaseController
class BaseController < ApplicationController
  helper_method :current_collection, :current_object

  load_and_authorize_resource
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  def index
  end

  def new
    @current_object = collection_scope.new
  end

  def create
    @current_object = collection_scope.new(resource_params)
    if @current_object.save
      respond_to do |f|
        f.html do
          flash[:success] ||= t('success.create')
          redirect_to url_after_create
        end
        f.json
      end
    else
      return render action: :new
    end
  end

  def destroy
    current_object.destroy
    respond_to do |f|
      f.html do
        flash[:success] ||= t('success.destroy')
        redirect_to url_after_destroy
      end
      f.json
    end
  end

  def edit
  end

  def update
    if current_object.update(resource_params)
      respond_to do |f|
        f.html do
          flash[:success] ||= t('success.update')
          redirect_to url_after_update
        end
        f.json
      end
    else
      respond_to do |f|
        f.html do |f|
          return render action: :edit
        end
        f.json
      end
    end
  end

  private

  # override in controller if needed
  def require_permission
    check_permission current_object.employee
  end

  def check_permission(object_owner)
    if current_employee != object_owner
      flash[:alert] = t('warnings.not_authorized')
      redirect_to root_path
    end
  end

  def url_after_create
    request.env['HTTP_REFERER'] || url_for(action: :index)
  end

  def url_after_destroy
    url_for(action: :index)
  end

  alias url_after_update url_after_create

  # You should implement these in your controller
  def collection_scope; end
  def resource_params; end

  def current_collection
    @current_collection ||= collection_scope.page(params[:page])
  end

  def current_object
    @current_object ||= collection_scope.find(params[:id])
  end
end
