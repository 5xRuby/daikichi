if defined?(Airbrake) && ENV.key?('ERRBIT_PROJECT_KEY') && ENV.key?('ERRBIT_HOST')
  Airbrake.configure do |config|
    config.host = ENV['ERRBIT_HOST']
    config.project_id = 1 # required, but any positive integer works
    config.project_key = ENV['ERRBIT_PROJECT_KEY']
    config.environment = ENV.fetch('ERRBIT_ENV') { 'development' }
    # airbrake.io supports various features that are out of scope for
    # Errbit. Disable them:
    config.job_stats           = false
    config.query_stats         = false
    config.performance_stats   = false
    config.remote_config       = false
  end
end
