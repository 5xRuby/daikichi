class Overtime < ApplicationRecord

  include AASM
  include SignatureConcern

  enum status:     Settings.leave_applications.statuses

  belongs_to :user
  belongs_to :manager, class_name: 'User', foreign_key: 'manager_id'

  validates :description, :start_time, :end_time, presence: true
  validate :hours_should_be_positive_integer
  validate :overlapped?

  before_validation :assign_hours

  scope :personal, ->(user_id, beginning, ending, status_array = %w(pending approved)) {
    where(status: status_array, user_id: user_id) }

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, before: [proc { |manager| sign(manager) }] do
      transitions to: :approved, from: :pending
    end

    event :reject, before: proc { |manager| sign(manager) } do
      transitions to: :rejected, from: %i(pending approved)
    end

    event :revise do
      transitions to: :pending, from: %i(pending approved)
    end

    event :cancel do
      transitions to: :canceled, from: :pending
      transitions to: :canceled, from: :approved, unless: :happened?
    end
  end  

  def happened?
    Time.current > self.start_time
  end

  private

  def assign_hours
    self.hours = ((end_time - start_time) / 3600).to_i if start_time && end_time
  end

  def overlapped?
    overlapped_records = Overtime.personal(user_id, start_time, end_time).where("end_time > ? AND start_time < ? AND id != ?", start_time, end_time, id)
    if overlapped_records.any?
      url = Rails.application.routes.url_helpers
      overlapped_records.each do |record|
        errors.add( :base,
                    I18n.t(
                      'activerecord.errors.models.overtime.attributes.base.time_range_overlapped',
                      start_time: record.start_time.to_formatted_s(:month_date),
                      end_time:   record.end_time.to_formatted_s(:month_date),
                      link:       url.overtime_path(id: record.id))
                    )
      end
    end
  end

  def hours_should_be_positive_integer
    return if errors[:start_time].any? or errors[:end_time].any?
    errors.add(:end_time, :not_integer) unless ((end_time - start_time).to_i % 3600).zero?
    errors.add(:start_time, :should_be_earlier) unless end_time > start_time
  end

end