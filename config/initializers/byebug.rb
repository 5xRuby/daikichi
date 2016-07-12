# bundle exec byebug -R localhost:{port}
if Rails.env.development? and ENV['BYEBUGPORT']
  require 'byebug/core'
  Byebug.start_server 'localhost', ENV['BYEBUGPORT'].to_i #set in .powenv
end
