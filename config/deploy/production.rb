set :deploy_to, '/home/deploy/daikichi.5xruby.tw'
role :app, %w{deploy@do.5xruby.com}
role :web, %w{deploy@do.5xruby.com}
role :db, %w{deploy@do.5xruby.com}
