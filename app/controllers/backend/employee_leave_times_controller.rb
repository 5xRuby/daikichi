class Backend::EmployeeLeaveTimesController < ApplicationController
  def index
  end

  private

  def collection_scope
    if params[:id]
      User
    else
      User.order(id: :desc)
    end
  end
end
