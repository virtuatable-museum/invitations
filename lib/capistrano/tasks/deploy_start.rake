namespace :deploy do
  desc 'Start the server'
  after :finishing, :start do
    on roles(:all) do
      within current_path do
        if test('[ -f /tmp/arkaan-campaigns.pid ]')
          puts 'Le fichier du PID a bien été trouvé et va être supprimé.'
          execute :kill, '-9 `cat /tmp/arkaan-campaigns.pid`'
        else
          puts "Le fichier du PID n'a pas été trouvé et ne peux pas être supprimé."
        end
        execute :bundle, 'exec rackup -p 9292 --env production -o 0.0.0.0 -P /tmp/arkaan-campaigns.pid --daemonize'
      end
    end
  end
end