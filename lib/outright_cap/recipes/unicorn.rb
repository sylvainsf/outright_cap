Capistrano::Configuration.instance(:must_exist).load do
  _cset(:unicorn_config) { "#{current_path}/config/unicorn.rb" }
  _cset(:unicorn_pid) { "#{shared_path}/pids/unicorn.pid" }
  
  namespace :unicorn do
    desc "Setup unicorn specific directories"
    task :setup, :roles => [:app], :except => { :no_release => true } do
      run "mkdir -p #{shared_path}/sockets/"
    end

    desc "Create links to for sockets and pids"
    task :finalize_update, :roles => [:app], :except => { :no_release => true } do
      run "cd #{current_path} && ln -sf #{shared_path}/sockets tmp/sockets"
      run "cd #{current_path} && ln -sf #{shared_path}/pids tmp/pids"
    end

    desc "Start unicorn from scratch"
    task :start, :roles => [:app], :except => { :no_release => true } do
      run "cd #{current_path}; #{sudo} bundle exec unicorn_rails -c #{unicorn_config} -E #{rails_env} -D || ( tail -100 #{current_path}/log/unicorn.errors ; exit 1 )"
    end

    desc "Gracefully stop unicorn from serving requests"
    task :stop, :roles => [:app], :except => { :no_release => true } do
      run "#{sudo} kill -QUIT `cat #{unicorn_pid}`; #{sudo} rm #{unicorn_pid}"
      unicorn.tail.stop
    end

    desc "Restart unicorn"
    task :restart, :roles => [:app], :except => { :no_release => true } do
      if find_servers_for_task(current_task).any?
        pid = capture("ps -ef | grep unicorn | grep -v grep | grep master | awk '{print $2 }'").chomp
        sudo "kill -USR2 `cat #{unicorn_pid}`"
        
        # Block until the new process is up
        puts "***\n*** Verifying unicorns are restarted. This may take a couple minutes.\n***"
        run "while [ `ps -ef | grep unicorn | grep -v grep | grep master | awk '{ print $2 }' | tail -n 1` -eq #{pid} ] ; do sleep 1; printf '.'; done ;"
      end
    end

    desc "Reopen log files"
    task :reopen_logs, :roles => [:app], :except => { :no_release => true } do
      sudo "kill -USR1 `cat #{unicorn_pid}`"
    end

    namespace :tail do
      task :default, :roles => [:app], :except => { :no_release => true } do
        run "tail -n0 -f #{shared_path}/log/unicorn.errors" do |channel, stream, data|
          puts data
        end
      end

      desc "Tail the log file for a stop or restart"
      task :stop, :roles => [:app], :except => { :no_release => true } do
        servers = self.parent.roles[:app].servers
        count = 0
        run "tail -n0 -f #{shared_path}/log/unicorn.errors" do |channel, stream, data|
          puts data
          if data.match(/master complete/)
            count += 1
            break if count == servers.size
          end
        end
      end
    end
  end
  
  namespace :deploy do
    desc "Start the application" 
    task :start, :roles => [:app], :except => { :no_release => true } do
      unicorn.start
    end

    desc "Restart the application" 
    task :restart, :roles => [:app], :except => { :no_release => true } do
      unicorn.restart
    end

    desc "Stop the application" 
    task :stop, :roles => [:app], :except => { :no_release => true } do
      unicorn.stop
    end
  end
  
  after "deploy:setup", "unicorn:setup"
  after "deploy:finalize_update", "unicorn:finalize_update"
  after "deploy:cold", "deploy:start"
end
