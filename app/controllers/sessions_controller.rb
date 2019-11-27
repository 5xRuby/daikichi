class SessionsController < ApplicationController
  if Rails.application.config.enable_sign_in_as
    def login_as
      sign_in(:user, User.find(params[:id]))
      redirect_to root_path
    end
  end
end
