# frozen_string_literal: true
class LeaveTimesController < BaseController
  STARTING_YEAR = Settings.misc.starting_year.to_i
  SHOWINGS = %i(all effective).freeze
  DEFAULT_SHOWING = 'effective'.freeze
  before_action :set_query_object

  helper_method :showing

  def index; end

  def showing
    @showing ||= params[:showing] || DEFAULT_SHOWING
  end

  private

  def collection_scope
    if params[:id]
      current_user.leave_times.preload(:user, leave_time_usages: :leave_application)
    else
      @q.result.preload(:user)
    end
  end

  def set_query_object
    @q = current_user.leave_times.ransack(search_params)
  end

  def search_params
    @search_params = params.fetch(:q, {})&.permit(:s, :leave_type_eq, :effective_true)
    @search_params.present? ? @search_params : @search_params.merge(effective_true: true)
  end
end
