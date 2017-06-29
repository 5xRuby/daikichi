# frozen_string_literal: true
namespace :import do
  desc "Automatically Import LeaveTime for Users whose join anniversary is comming"
  task import: :environment do
    LeaveTimeBatchBuilder.new.automatically_import
  end
end
