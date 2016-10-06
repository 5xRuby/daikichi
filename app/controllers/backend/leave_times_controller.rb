class Backend::LeaveTimesController < Backend::BaseController

  def index
    @current_collection = @leave_times.get_employees_bonus
  end

  def edit
    @current_object = @leave_time
  end

  def update
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
