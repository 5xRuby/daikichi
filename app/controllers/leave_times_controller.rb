# frozen_string_literal: true
class LeaveTimesController < BaseController
  private

  def collection_scope
    current_user.leave_times
  end
end
