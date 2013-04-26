require File.expand_path('./deploy/recipes/capistrano-database', File.dirname(__FILE__))
require "bundler/capistrano"

ssh_options[:compression] = "none"
default_run_options[:pty] = true

set :application, 'railsconf'
set :repository,  'git@github.com:dockyard/realtime-rails.git'
set :branch, 'master'

set :scm, :git

set :user, 'puma'
set :use_sudo, false

role :web, 'railsconf2013.dockyard.com'
role :app, 'railsconf2013.dockyard.com'
role :db, 'railsconf2013.dockyard.com', :primary => true

set :deploy_to, '/var/www/railsconf'

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => :app do
    run "cd #{release_path} && sudo bundle exec foreman export upstart /etc/init -a #{application} -u #{user} -l #{shared_path}/log"
  end
  desc "Start the application services"
  task :start, :roles => :app do
    sudo "sudo start #{application}"
  end

  desc "Stop the application services"
  task :stop, :roles => :app do
    sudo "sudo stop #{application}"
  end

  desc "Restart the application services"
  task :restart, :roles => :app do
    run "sudo start #{application} || sudo restart #{application}"
  end
end

#after 'deploy:update', 'symlink:database'
#after 'deploy:update', 'symlink:env'
after 'deploy:update', 'foreman:export'
after 'deploy:update', 'foreman:restart'

namespace :symlink do
  task :database do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  task :env do
    run "ln -nfs #{shared_path}/config/env #{release_path}/.env"
  end
end
