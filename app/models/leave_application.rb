# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  has_many :leave_application_logs, foreign_key: "leave_application_uuid", primary_key: "uuid"
  validates :leave_type, :description, presence: true
  validate :hours_should_be_positive_integer
  after_initialize :set_primary_id
  before_create :deduct_leave_time_usable_hours
  acts_as_paranoid

  LEAVE_TYPE = %i(bonus personal sick).freeze

  include AASM
  include SignatureConcern

  aasm column: :status do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, after: proc { |manager| sign(manager) } do
      transitions to: :approved, from: [:pending]
    end

    event :reject, after: [proc { |manager| sign(manager) }, :return_leave_time_usable_hours] do
      transitions to: :rejected, from: [:pending]
    end

    event :revise, after: :deduct_leave_time_usable_hours do
      transitions to: :pending, from: [:pending, :approved, :rejected]
    end

    event :cancel, after: :return_leave_time_usable_hours do
      transitions to: :canceled, from: [:pending, :approved, :rejected]
    end
  end

  def pending?
    self.status == "pending"
  end

  def canceled?
    self.status == "canceled"
  end

  private

  def set_primary_id
    self.uuid ||= SecureRandom.uuid
  end

  def deduct_leave_time_usable_hours
    leave_time, leave_time_for_annual = LeaveTime.get_general_and_annual user_id, leave_type
    prior_used_hours = leave_time.used_hours
    prior_annual_used_hours = leave_time_for_annual.used_hours

    if leave_application_logs.any? || (aasm.to_state =~ /rejected|canceled/).present? && aasm.from_state == "rejected"
      newest_log = leave_application_logs.last
      leave_time.add_back newest_log.general_hours, newest_log.annual_hours unless newest_log.returning?
    end

    assign_hours
    leave_time.deduct hours
    save! if leave_application_logs.any?

    leave_time.reload
    leave_time_for_annual.reload
    LeaveApplicationLog.create!(leave_application_uuid: self.uuid,
                                general_hours: (leave_time.used_hours - prior_used_hours),
                                annual_hours: (leave_time_for_annual.used_hours - prior_annual_used_hours))
  end

  def return_leave_time_usable_hours
    if aasm.from_state != :rejected
      leave_time, leave_time_for_annual = LeaveTime.get_general_and_annual user_id, leave_type
      prior_used_hours = leave_time.used_hours
      prior_annual_used_hours = leave_time_for_annual.used_hours

      newest_log = leave_application_logs.last
      leave_time.add_back newest_log.general_hours, newest_log.annual_hours

      leave_time.reload
      leave_time_for_annual.reload
      LeaveApplicationLog.create!(leave_application_uuid: self.uuid,
                                  general_hours: (-leave_time.used_hours + prior_used_hours),
                                  annual_hours: (-leave_time_for_annual.used_hours + prior_annual_used_hours),
                                  returning?: true)
    end
  end

  def assign_hours
    self.hours = start_time.working_time_until(end_time) / 3600.0
  end

  def hours_should_be_positive_integer
    errors.add(:end_time, :not_integer) unless (((end_time - start_time) / 3600.0) % 1).zero?
    errors.add(:start_time, :should_be_earlier) unless end_time > start_time
  end
end
