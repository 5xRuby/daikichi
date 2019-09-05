Rails.application.config.generators do |g|
  g.test_framework :rspec, view_specs: false
  g.fixture_replacement :factory_bot, dir: 'spec/factories'
end
