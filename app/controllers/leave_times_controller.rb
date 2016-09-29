# frozen_string_literal: true
class LeaveTimesController < BaseController
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
