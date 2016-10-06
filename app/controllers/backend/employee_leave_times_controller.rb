# frozen_string_literal: true
class Backend::EmployeeLeaveTimesController < Backend::BaseController
  skip_load_and_authorize_resource

  def index
    @current_collection = collection_scope.total_leave_times_hours(params[:year], params[:month])
    authorize! action_name, @current_collection
  end

  def collection_scope
    EmployeeMonthlyStat
  end
end
