class LeaveTimeSummaryService
  def initialize(year, month, role = %w(employee parttime))
    @range = (
      Time.zone.local(year, month).beginning_of_month..
      Time.zone.local(year, month).end_of_month
    )
    @types = Settings.leave_times.quota_types.keys
    @role = role
  end

  def user_applications
    @user_applications ||= LeaveApplication.where(user: User.filter_by_role(@role)).leave_within_range(@range.min, @range.max)
      .approved
      .includes(:leave_time_usages, :leave_times)
      .group_by(&:user_id)
  end

  def application_to_usage(applications)
    applications.map(&:leave_time_usages)
      .flatten
      .group_by { |usage| usage.leave_time.leave_type }
      .map { |k, v| [k, used_hours_in_month(v).sum] }
  end

  def summary
    @summary ||= Hash[
      user_applications.map do |(id, applications)|
        [
          id,
          default_columns.merge(Hash[application_to_usage(applications)])
        ]
      end
    ]
  end

  private

  def default_columns
    Hash[@types.collect { |type| [type, 0] }]
  end

  def used_hours_in_month(usages)
    usages_in_month(usages).map(&:used_hours)
  end

  def usages_in_month(usages)
    usages.select { |usage| usage.date.between? @range.min, @range.max }
  end
end
