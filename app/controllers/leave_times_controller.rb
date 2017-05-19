# frozen_string_literal: true
class LeaveTimesController < BaseController
  STARTING_YEAR = Settings.misc.starting_year.to_i
  SHOWINGS = %i(all effective)
  DEFAULT_SHOWING = 'effective'
  before_action :set_query_object

  helper_method :showing

  def index; end

  def show
    leave_type = params[:type]
    leave_time = LeaveTime.personal current_user.id, leave_type

    respond_to do |format|
      format.json { render json: leave_time }
    end
  end

  def showing
    @showing ||= params[:showing] || DEFAULT_SHOWING
  end

  private

  def collection_scope
    if params[:id]
      LeaveTime
    else
      @q.result.preload(:user)
    end
  end

  def set_query_object
    @q = LeaveTime.belong_to(current_user).ransack(search_params)
  end

   def search_params
    params.fetch(:q, {})&.permit(:s, :leave_type_eq, :effective_true)
  end
end
