# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  include AASM
  include SignatureConcern

  delegate :name, to: :user, prefix: true

  enum status:     Settings.leave_applications.statuses
  enum leave_type: Settings.leave_applications.leave_types

  acts_as_paranoid
  paginates_per 15

  belongs_to :user
  belongs_to :manager, class_name: 'User', foreign_key: 'manager_id'
  has_many   :leave_times, through: :leave_time_usages
  has_many   :leave_time_usages
  has_many   :leave_hours_by_dates, dependent: :delete_all

  validates :leave_type, :description, :start_time, :end_time, presence: true

  validate :hours_should_be_positive_integer
  validate :should_not_overlaps_other_applications

  scope :leave_within_range, ->(beginning = Daikichi::Config::Biz.periods.after(1.month.ago.beginning_of_month).first.start_time, closing = Daikichi::Config::Biz.periods.before(1.month.ago.end_of_month).first.end_time.localtime) {
    where(
      '(leave_applications.start_time, leave_applications.end_time) OVERLAPS (timestamp :beginning, timestamp :closing)',
      beginning: beginning, closing: closing
    )
  }

  scope :personal, ->(user_id, beginning, ending, status_array = %w[pending approved]) {
    where(status: status_array, user_id: user_id).leave_within_range(beginning, ending)
  }

  scope :with_status, ->(status) { where(status: status) }
  scope :with_year,   ->(year = Time.current.year) {
    leave_within_range(Time.zone.local(year).beginning_of_year, Time.zone.local(year).end_of_year)
  }

  scope :with_leave_application_statistics, ->(year = Date.current.year, month = Date.current.month) {
    joins(:leave_hours_by_dates, :leave_times)
      .merge(LeaveHoursByDate.where(date: Date.new(year, month, 15).beginning_of_month..Date.new(year, month, 15).end_of_month))
      .approved
      .leave_within_range(Time.zone.local(year, month, 1).beginning_of_month, Time.zone.local(year, month, 1).end_of_month)
      .select('leave_applications.user_id, leave_times.leave_type as quota_type, sum(leave_hours_by_dates.hours) as sum')
      .preload(:user)
      .group(:user_id, 'leave_times.leave_type')
  }

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :approved
    state :rejected
    state :canceled

    event :approve, before: [proc { |manager| sign(manager) }] do
      transitions to: :approved, from: :pending, guard: :check_special_leave_application_quota
    end

    event :reject, before: proc { |manager| sign(manager) } do
      transitions to: :rejected, from: :pending
    end

    event :revise do
      transitions to: :pending, from: %i[pending approved]
    end

    event :cancel do
      transitions to: :canceled, from: :pending
      transitions to: :canceled, from: :approved, unless: :happened?
    end
  end

  ransacker :start_date do
    Arel.sql("DATE((#{table_name}.start_time AT TIME ZONE 'UTC') AT TIME ZONE 'Asia/Taipei')")
  end

  ransacker :end_date do
    Arel.sql("DATE((#{table_name}.end_time AT TIME ZONE 'UTC') AT TIME ZONE 'Asia/Taipei')")
  end

  def happened?
    Time.current > self.start_time
  end

  def check_special_leave_application_quota
    return true unless self.special_type?
    self.leave_time_usages.any? or self.available_leave_times.pluck(:usable_hours).sum >= self.hours
  end

  def aasm_event?(event)
    [event, :"#{event}!"].include? aasm.current_event
  end

  def special_type?
    %w(marriage bereavement official maternity).include? self.leave_type
  end

  def available_leave_times
    self.user.leave_times
      .where(leave_type: Settings.leave_applications.available_quota_types.send(self.leave_type))
      .where('usable_hours > 0')
      .overlaps(start_time.beginning_of_day, end_time.end_of_day)
      .order(order_by_sequence)
      .order(:expiration_date, :usable_hours)
  end

  def interval_changed?
    @interval_changed ||= self.new_record? || self.start_time_changed? || self.end_time_changed?
  end

  def leave_time_params
    {
      user_id: self.user_id,
      leave_type: self.leave_type,
      effective_date: self.start_time.to_date,
    }
  end

  def self.statistics_table(month: Date.current.month, year: Date.current.year)
    records = LeaveApplication.with_leave_application_statistics(year, month)
    grid = PivotTable::Grid.new do |g|
      g.source_data = records
      g.column_name = :quota_type
      g.row_name    = :user_name
      g.value_name  = :sum
    end
    grid.build
  end

  private

  def auto_calculated_minutes
    return @minutes = 0 unless start_time && end_time
    @minutes = Daikichi::Config::Biz.within(start_time, end_time).in_minutes
  end

  def hours_should_be_positive_integer
    return if self.errors[:start_time].any? or self.errors[:end_time].any?
    errors.add(:end_time, :not_integer) if (@minutes % 60).nonzero? || !self.hours.positive?
    errors.add(:start_time, :should_be_earlier) unless self.end_time > self.start_time
  end

  def should_not_overlaps_other_applications
    return if self.errors[:start_time].any? or self.errors[:end_time].any?
    overlapped = LeaveApplication.personal(user_id, start_time, end_time).where.not(id: self.id)
    return unless overlapped.any?
    overlap_application_error_messages(overlapped)
  end

  def overlap_application_error_messages(leave_applications)
    url = Rails.application.routes.url_helpers
    leave_applications.each do |la|
      errors.add(
        :base,
        I18n.t(
          'activerecord.errors.models.leave_application.attributes.base.overlap_application',
          leave_type: LeaveApplication.human_enum_value(:leave_type, la.leave_type),
          start_time: la.start_time.to_formatted_s(:month_date),
          end_time:   la.end_time.to_formatted_s(:month_date),
          link:       url.leave_application_path(id: la.id)
        )
      )
    end
  end

  def order_by_sequence
    format 'array_position(Array%s, leave_type::TEXT)', Settings.leave_applications.available_quota_types.send(self.leave_type).to_s.tr('"', "'")
  end
end
