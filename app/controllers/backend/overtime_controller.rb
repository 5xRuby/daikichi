# frozen_string_literal: true
class Backend::OvertimeController < Backend::BaseController
  include Selectable
  before_action :set_query_object

  def index
    @users = User.all
  end

  private

  def collection_scope
    if params[:id]
      Overtime
    else
      @q.result.preload(:user)
    end
  end

  def search_params
    @search_params = params.fetch(:q, {})&.permit(
      :s, :user_id_eq, :status_eq, :end_time_gteq, :start_time_lteq)
    @search_params.present? ? @search_params : @search_params.merge(status_eq: :pending)
  end

  def set_query_object
    @q = Overtime.ransack(search_params)
  end
end
