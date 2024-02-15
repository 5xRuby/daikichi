# frozen_string_literal: true

Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = false
  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception) }
  config.good_job.execution_mode = :async
  config.good_job.queues = '*'
  config.good_job.max_threads = 5
  config.good_job.poll_interval = 30 # seconds
  config.good_job.shutdown_timeout = 25 # seconds
  config.good_job.enable_cron = true
  config.good_job.dashboard_default_locale = :en
  config.good_job.cron = {
    import: {
      cron: '0 0 * * *',
      class: 'ImportJob'
    }
  }
end

ActiveSupport.on_load(:good_job_application_controller) do
  # context here is GoodJob::ApplicationController

  before_action do
    raise ActionController::RoutingError, 'Not Found' unless current_user&.role == 'manager'
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end
