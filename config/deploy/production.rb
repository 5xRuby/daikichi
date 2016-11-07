set :deploy_to, '/home/5xruby/daikichi.5xruby.tw'
role :app, %w{5xruby@hq.5xruby.tw:14159}
role :web, %w{5xruby@hq.5xruby.tw:14159}
role :db, %w{5xruby@hq.5xruby.tw:14159}
