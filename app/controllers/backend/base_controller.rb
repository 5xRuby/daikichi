module Backend
  # Backend::BaseController
  class BaseController < ::BaseController
    before_action :verify_manager

    private

    def verify_manager
      unless current_user.manage?
        flash[:alert] = t('warnings.not_authorized')
        redirect_to root_url
      end
    end
  end
end
