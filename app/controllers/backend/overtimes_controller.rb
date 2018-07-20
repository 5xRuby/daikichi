class Backend::OvertimesController < Backend::BaseController

  before_action :set_query_object

  def index
    @users = User.all
  end

  private

  def set_query_object
    @q = Overtime.ransack(search_params)
  end

  def search_params
    @search_params = params.fetch(:q, {})&.permit(
      :s, :status_eq, :end_time_lteq, :start_time_gteq)
  end

  def collection_scope
    @q.result.preload(:user)
  end

end