class Backend::BaseController < ::ApplicationController
  load_and_authorize_resource
  before_action :verify_manager

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  private

  def verify_manager
    unless current_user.role == 'manager'
      flash[:alert] = t('warnings.not_authorized')
      redirect_to root_url
    end
  end
end
