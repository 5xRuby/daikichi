# frozen_string_literal: true
module Selectable
  def status_selected?
    LeaveApplication.aasm.states.map(&:name).include? params[:status]&.to_sym
  end
end
