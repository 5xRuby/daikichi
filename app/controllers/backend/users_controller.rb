module Backend
  # Backend::UsersContoller
  class UsersController < Backend::BaseController
    def show
      @leave_times = LeaveTime.current_year(params[:id])
    end

    def collection_scope
      if params[:id]
        User
      else
        User.order(id: :desc)
      end
    end

    private

    def resource_params
      params.require(:user).permit(
        :name, :email, :login_name, :role,
        :password, :password_confirmation,
        :join_date, :leave_date
      )
    end
  end
end
