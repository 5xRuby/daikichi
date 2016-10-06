class Backend::LeaveTimesController < Backend::BaseController

  def index
  end

  def edit
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
