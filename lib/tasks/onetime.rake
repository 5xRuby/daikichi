# frozen_string_literal: true

namespace :onetime do
  desc "強制修正有問題的假單"
  task rebuild_leave_time_usages_of_leave_application: :environment do
    ids = ENV['IDS'].split(",").map(&:to_i)
    ids.each do |laid|
      LeaveApplication.find(laid).rebuild_leave_time_usages!
    end
  end
end
