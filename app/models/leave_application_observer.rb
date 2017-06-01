# frozen_string_literal: true
class LeaveApplicationObserver < ActiveRecord::Observer
  observe LeaveApplication

  def before_save(record)
    cleanup_leave_hours_by_date(record)
  end

  def after_save(record)
    create_leave_hours_by_date(record)
  end

  private

  def cleanup_leave_hours_by_date(record)
    record.leave_hours_by_dates.delete_all if record.persisted? && record.interval_changed?
  end

  def create_leave_hours_by_date(record)
    return unless record.interval_changed?
    leave_hours_by_dates = LeaveTimeUsageBuilder.new(record).leave_hours_by_date.map do |date|
      record.leave_hours_by_dates.build(date: date.first, hours: date.second)
    end
    LeaveHoursByDate.import leave_hours_by_dates, validate: true
  end
end
