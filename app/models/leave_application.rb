# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  acts_as_paranoid

  LEAVE_TYPE = %i(annual bonus personal sick).freeze

  include AASM
  include SignatureConcern

  aasm column: :status do
    state :pending, initial: true
    state :approved
    state :rejected
    state :closed

    event :approve, after: proc { |manager| sign(manager) } do
      transitions to: :approved, from: [:pending, :rejected]
    end

    event :reject, after: proc { |manager| sign(manager) } do
      transitions to: :rejected, from: [:pending, :approved]
    end

    event :revise do
      transitions to: :pending, from: [:pending, :approved, :rejected]
    end

    event :close do
      transitions to: :closed, from: [:pending, :approved, :rejected]
    end
  end
end
