case ENV['RAILS_ENV']
when 'production'
  job_type :rake, "cd :path && :environment_variable=:environment /usr/local/ruby26/bin/bundle exec rake :task --silent :output"
else
end

# 每日 00:00 檢查是否初始化額度（Monthly and Join_date_base）
every "0 0 * * *" do
  rake "import:import"
end
