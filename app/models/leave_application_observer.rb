# frozen_string_literal: true

class LeaveApplicationObserver < ActiveRecord::Observer
  observe LeaveApplication

  def before_validation(record)
    assign_hours(record)
  end

  def before_save(record)
    cleanup_leave_hours_by_date(record)
  end

  def after_save(record)
    create_leave_hours_by_date(record)
  end

  def after_create(record)
    create_leave_time_usages(record)
    FlowdockService.new(leave_application: record).send_create_notification if Rails.env.production?
    InformationMailer.new_application(record).deliver_later if Rails.env.production?
  end

  def before_update(record)
    hours_transfer(record)
  end

  def after_update(record)
    create_leave_time_usages(record) if record.aasm_event?(:revise)
    FlowdockService.new(leave_application: record).send_update_notification(record.aasm.to_state) if Rails.env.production?
    UserMailer.reply_leave_applicaiton_email(record).deliver_later if record.aasm_event?(:approve) or record.aasm_event?(:reject)
    InformationMailer.cancel_application(record).deliver_later if record.aasm_event?(:cancel) && Rails.env.production?
  end

  private

  def assign_hours(record)
    record.hours = record.send(:auto_calculated_minutes) / 60
  end

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

  def create_leave_time_usages(record)
    raise ActiveRecord::Rollback if !LeaveTimeUsageBuilder.new(record).build_leave_time_usages and !record.special_type?
  end

  def hours_transfer(record)
    case
    when record.aasm_event?(:approve) then transfer_locked_hours_to_used_hours(record)
    when record.aasm_event?(:reject)  then return_leave_time_usable_hours(record)
    when record.aasm_event?(:cancel)  then return_leave_time_usable_hours(record)
    when record.aasm_event?(:revise)  then return_leave_time_usable_hours(record)
    end
  end

  def transfer_locked_hours_to_used_hours(record)
    record.leave_time_usages.each { |usage| usage.leave_time.use_hours!(usage.used_hours) }
  end

  def return_leave_time_usable_hours(record)
    record.leave_time_usages.each { |usage| revert_hours(record, usage) }
    record.leave_time_usages.destroy_all
  end

  def revert_hours(record, usage)
    usage.reload
    return usage.leave_time.unlock_hours!(usage.used_hours) if record.aasm.from_state == :pending
    return usage.leave_time.unuse_hours!(usage.used_hours) if record.aasm.from_state == :approved
    raise ActiveRecord::Rollback
  end
end
