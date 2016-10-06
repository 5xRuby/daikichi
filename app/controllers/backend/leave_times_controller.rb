# frozen_string_literal: true
class Backend::LeaveTimesController < Backend::BaseController
  def index
    @current_collection = @leave_times.get_employees_bonus
  end

  private

  def collection_scope
    if params[:id]
      LeaveTime
    else
      LeaveTime.order(id: :desc)
    end
  end
end
