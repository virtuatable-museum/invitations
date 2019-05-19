lock '~> 3.11.0'

set :application, 'virtuatable-invitations'
set :deploy_to, '/var/www/invitations'
set :repo_url, 'git@github.com:jdr-tools/invitations.git'
set :branch, 'master'

append :linked_files, 'config/mongoid.yml'
append :linked_files, '.env'
append :linked_dirs, 'bundle'
append :linked_dirs, 'log'