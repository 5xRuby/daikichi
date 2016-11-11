# frozen_string_literal: true
namespace :dev do
  desc "Rebuild system"
  task rebuild: ["tmp:clear", "log:clear", "db:drop", "db:create", "db:migrate" ] do
    Rake::Task["import_data:users"].invoke
    Rake::Task["leave_time:init"].invoke(Time.now.year, "force")
    Rake::Task["import_data:bonus_leave_times"].invoke
    Rake::Task["import_data:leaves"].invoke
    puts "rebuild success"
  end
end
