# frozen_string_literal: true
class LeaveTimesController < BaseController
  STARTING_YEAR = Settings.misc.starting_year.to_i
  SHOWINGS = (%i(all effective)).freeze
  DEFAULT_SHOWING = 'effective'

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
    return LeaveTime if params[:id]
    lts = LeaveTime.belong_to(current_user)
    case showing
    when 'all'
      lts
    else
      if /\A\d+\z/.match(showing)
        showing_tmp = showing.to_i
        lts.overlaps(
          Date.new(showing_tmp, 1, 1), Date.new(showing_tmp, 12, 31)
        )
      else # 'effective'
        lts.effective
      end
    end
  end
end
