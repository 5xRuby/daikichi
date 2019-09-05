class OvertimesController < BaseController
  include Selectable

  def index
    @q = current_user.overtimes.order(created_at: :desc).ransack(search_params)
    @current_collection = @q.result.page(params[:page])
    @current_collection = Kaminari.paginate_array(@current_collection.first(5)).page(params[:page]) unless params[:q].present?
  end

  def new
    @current_object = collection_scope.new
  end

  def create
    @current_object = collection_scope.new(resource_params)
    if @current_object.save
      action_success
    else
      render action: :new
    end
  end

  def update
    if current_object.canceled?
      action_fail t('warnings.not_cancellable'), :edit
    else
      current_object.assign_attributes(resource_params)
      if !current_object.changed?
        action_fail t('warnings.no_change'), :edit
      elsif current_object.revise!
        action_success
      else
        render action: :edit
      end
    end
  end

  def cancel
    if current_object.may_cancel?
      current_object.cancel!
      @actions << :cancel
      action_success
    elsif current_object.approved?
      action_fail t('warnings.already_happened'), :index
    else
      action_fail t('warnings.not_cancellable'), :index
    end
  end

  private

  def resource_params
    params.require(:overtime).permit(
      :start_time, :end_time, :description, :compensatory_type
    )
  end

  def collection_scope
    current_user.overtimes
  end

  def search_params
    @search_params = params.fetch(:q, {})&.permit(
      :status_eq, :end_time_lteq, :start_time_gteq, :compensatory_type_eq)
  end
end
