class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def keycloak
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user
      sign_in(:user, @user)
      redirect_to root_path, notice: I18n.t("devise.sessions.signed_in")
    else
      redirect_to root_path, alert: I18n.t("devise.failure.not_found_in_database")
    end
  end

  def failure
    redirect_to root_path
  end
end