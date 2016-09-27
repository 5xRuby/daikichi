# frozen_string_literal: true
class Backend::EmployeeLeaveTimesController < Backend::BaseController
  before_action :custom_authorize
  skip_load_and_authorize_resource

  def index
    @current_collection = EmployeeMonthlyStat.total_leave_times_hours(params[:year], params[:month])
  end

  private

  def custom_authorize
    authorize! action_name, @current_collection
    authorize! action_name, @current_object
  end

  def collection_scope
    if params[:id]
      User
    else
      User.order(id: :desc)
    end
  end
end
