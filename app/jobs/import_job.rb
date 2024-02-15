class ImportJob < ApplicationJob
  queue_as :default

  def perform(*args)
    LeaveTimeBatchBuilder.new.automatically_import
  end
end
