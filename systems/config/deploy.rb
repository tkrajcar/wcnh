default_run_options[:pty] = true  # Must be set for the password prompt from git to work
ssh_options[:forward_agent] = true

set :application, "wcnh_systems"
set :repository,  "git@github.com:tkrajcar/wcnh_systems.git"

set :scm, :git
set :branch, "master"
set :deploy_to, "/home/wcnh/systems/"

set :deploy_via, :remote_cache

server "wcmush.com", :app
set :user, "wcnh"
