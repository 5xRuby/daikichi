# frozen_string_literal: true
class LeaveTimesController < BaseController
  def index
    # FIXME: This won't work since LeaveTime's structure has changed
    @current_collection = collection_scope.overlaps(
      Date.new(specific_year.to_i, 1, 1), Date.new(specific_year.to_i, 12, 1)
    ).page(params[:page])
  end

  def show
    leave_type = params[:type]
    leave_time = LeaveTime.personal current_user.id, leave_type

    respond_to do |format|
      format.json { render json: leave_time }
    end
  end

  private

  def collection_scope
    current_user.leave_times
  end
end
