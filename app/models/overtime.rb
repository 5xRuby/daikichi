# frozen_string_literal: true
class Overtime < ApplicationRecord
  include AASM
  include SignatureConcern

  enum status: Settings.overtimes.statuses
  enum compensatory_type: Settings.overtimes.compensatory_types

  belongs_to :user
  belongs_to :manager, class_name: 'User', foreign_key: 'manager_id'

  has_one :overtime_pay

  validates :description, :start_time, :end_time, :compensatory_type, presence: true
  validate :hours_should_be_positive_integer
  validate :time_overlapped

  before_validation :assign_hours

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, before: proc { |manager| sign(manager) } do
      transitions to: :approved, from: :pending
    end

    event :reject, before: proc { |manager| sign(manager) } do
      transitions to: :rejected, from: %i(pending approved)
    end

    event :revise do
      transitions to: :pending, from: %i(pending)
    end

    event :cancel do
      transitions to: :canceled, from: %i(pending approved)
    end
  end

  private

  def leave_time_params
    {
      user_id: self.user_id,
      leave_type: 'bonus',
      quota: self.hours,
      effective_date: self.start_time.to_date,
      expiration_date: self.start_time.to_date.end_of_year
    }
  end

  ransacker :year do
    Arel.sql('extract(year from created_at)')
  end

  ransacker :month do
    Arel.sql('extract(month from created_at)')
  end

  private

  def assign_hours
    return unless start_time && end_time
    self.hours = ((end_time - start_time) / 3600).to_i 
  end

  def hours_should_be_positive_integer
    return if errors.any?
    errors.add(:end_time, :not_integer) unless ((end_time - start_time).to_i % 3600).zero?
    errors.add(:start_time, :should_be_earlier) unless end_time > start_time
  end

  def time_overlapped
    return if errors.any?
    overlapped_records = Overtime.where('(start_time, end_time) OVERLAPS (?, ?)', start_time , end_time).where.not(id: self.id)
    return unless overlapped_records.any?
    time_overlapped_errors(overlapped_records)
  end

  def time_overlapped_errors(records)
    url = Rails.application.routes.url_helpers
    records.each do |record|
      next if record.rejected? || record.canceled?
      errors.add(:base,
                 I18n.t(
                   'activerecord.errors.models.overtime.attributes.base.time_range_overlapped',
                   start_time: record.start_time.to_formatted_s(:month_date),
                   end_time:   record.end_time.to_formatted_s(:month_date),
                   link:       url.overtime_path(id: record.id))
                )
    end
  end
end
