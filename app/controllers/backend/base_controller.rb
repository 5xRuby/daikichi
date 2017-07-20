# frozen_string_literal: true
class Backend::BaseController < ::BaseController
  before_action :authenticate_hr!

  def authenticate_hr!
    redirect_to root_path unless current_user.is_hr? || current_user.is_manager?
  end

  def authenticate_manager!
    redirect_to root_path unless current_user.is_manager?
  end
end
