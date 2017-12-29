class LeaveTimeSummaryService
  def initialize(year, month)
    @range = (
      Time.zone.local(year, month).beginning_of_month..
      Time.zone.local(year, month).end_of_month
    )
    @types = Settings.leave_times.quota_types.keys
  end

  def user_applications
    @user_applications ||= LeaveApplication.leave_within_range(@range.min, @range.max)
                                           .approved
                                           .includes(:leave_time_usages, :leave_times)
                                           .group_by { |application| application.user_id }
  end

  def application_to_usage(applications)
    applications.map(&:leave_time_usages)
                .flatten
                .group_by { |usage| usage.leave_time.leave_type }
                .map { |k, v| [k, [ not_across_month_application?(v) ,usage_in_month(v).sum]] }

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
    Hash[@types.collect { |type| [type, 0]}]
  end

  def usage_in_month(usages)
    usages.map do |usage|
      usage.used_hours
    end
  end

  def hours_in_month_of(usage)
    ((@range.max - usage.leave_application.start_time) / 86400).floor * 8
  end

  def not_across_month_application?(usages)
    usages.map(&:leave_application).each do |application|
      return application.end_time.between?(@range.min, @range.max)
    end
  end

  # def not_across_month_application?(application)
  #   application.end_time.between?(@range.min, @range.max)
  # end

end