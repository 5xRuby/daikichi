# frozen_string_literal: true
namespace :generate_usages do
  desc "Generate leave time usage in new format for approved applications"
  task approved: :environment do
    LeaveApplication.approved.find_each do |la|
      la.leave_time_usages.each do |usage|
        usage.leave_time.unuse_hours!(usage.used_hours)
        usage.destroy
      end
      raise ActiveRecord::Rollback if !LeaveTimeUsageBuilder.new(la).build_leave_time_usages and !la.special_type?
    end
    
    LeaveApplication.approved.find_each do |la|
      la.leave_time_usages.group_by(&:leave_time_id).each do |usages|
        leave_time = LeaveTime.find(usages[0])
        leave_time.use_hours!(usages[1].sum(&:used_hours))
      end
    end
  end

  desc "Generate leave time usage in new format for pending leave applications"
  task pending: :environment do 
    LeaveApplication.pending.find_each do |la|
      la.leave_time_usages.each do |usage|
        usage.leave_time.unlock_hours!(usage.used_hours)
        usage.destroy
      end
      raise ActiveRecord::Rollback if !LeaveTimeUsageBuilder.new(la).build_leave_time_usages and !la.special_type?
    end
  end
end
