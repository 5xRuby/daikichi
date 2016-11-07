# frozen_string_literal: true
class Backend::UsersController < Backend::BaseController
  before_action :set_minimum_password_length, only: [:new, :edit]

  def show
    @leave_times = LeaveTime.current_year(params[:id])
  end

  private

  def collection_scope
    if params[:id]
      User
    else
      User.order(id: :desc)
    end
  end

  def resource_params
    params.require(:user).permit(
      :name, :email, :login_name, :role,
      :password, :password_confirmation,
      :join_date, :leave_date
    )
  end

  def set_minimum_password_length
    @minimum_password_length = 6
  end
end
