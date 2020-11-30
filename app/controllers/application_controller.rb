# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_raven_context

  protected

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options(options = {})
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:login_name, :email, :name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:login_name, :name])
  end

  def set_raven_context
    Raven.user_context(id: current_user.id, email: current_user.email) if current_user.present?
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
