# config valid only for current version of Capistrano
lock '3.8.1'

set :application, 'daikichi'
set :repo_url, 'https://github.com/5xruby/daikichi'

# Default branch is :master
#
if ENV['USE_CURRENT_BRANCH'].to_i > 0
  set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
elsif ENV.has_key?('USE_BRANCH')
  set :branch, ENV['USE_BRANCH']
else
  ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
end

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

# Default value for :pty is false
set :pty, false

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/application.yml config/secrets.yml config/fluent-logger.yml}


# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log')

# Default value for default_env is {}
set :default_env, { path: "$PATH:/usr/local/ruby23/bin:/usr/local/ruby-2.4.1/bin:" }

# Default value for keep_releases is 5
set :keep_releases, 3

set :crono_pid, -> { File.join(shared_path, 'tmp', 'pids', 'crono.pid') }
set :crono_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
set :crono_log, -> { File.join(shared_path, 'log', 'crono.log') }
set :crono_role, -> { :app }

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        execute :rake, 'tmp:clear'
      end
    end
  end

end
after :'deploy:publishing', :'deploy:restart'
