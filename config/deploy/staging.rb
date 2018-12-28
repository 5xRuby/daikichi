set :deploy_to, '/home/deploy/daikichi.5xruby.tw'
role :app, %w{deploy@staging-srv.5xruby.tw}
role :web, %w{deploy@staging-srv.5xruby.tw}
role :db, %w{deploy@staging-srv.5xruby.tw}
