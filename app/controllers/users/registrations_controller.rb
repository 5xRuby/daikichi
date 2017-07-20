# frozen_string_literal: true
class Users::RegistrationsController < Devise::RegistrationsController
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  def new
    authorize! action_name, User
  end
end
