# frozen_string_literal: true
class Backend::LeaveTimesController < Backend::BaseController
  def index
      @current_collection = collection_scope.get_employees_bonus.page(params[:page]).reorder(user_id: :desc)
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
