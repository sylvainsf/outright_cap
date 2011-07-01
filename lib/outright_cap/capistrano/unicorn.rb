Capistrano::Configuration.instance(:must_exist).load do
  namespace :unicorn do
    desc "Setup unicorn specific directories"
    task :setup, :roles => [:app], :except => { :no_release => true } do
      run "mkdir -p #{shared_path}/sockets/"
    end

    desc "Create symlink"
    namespace :symlink do
      task :default do
        matched = get_servers(self, :roles => [:app], :except => { :no_release => true})
        if matched.size > 0
          unicorn.symlink.on_servers
        end
      end
      task :on_servers, :roles => [:app], :except => { :no_release => true } do
        run "cd #{current_path} && ln -sf #{shared_path}/sockets tmp/sockets"
        run "cd #{current_path} && ln -sf #{shared_path}/pids tmp/pids"
      end
    end

    desc "Start unicorn from scratch"
    task :start, :roles => [:app], :except => { :no_release => true } do
      if !pid_is_running?(unicorn_pid)
        run "cd #{current_path}; #{sudo} bundle exec unicorn_rails -c #{unicorn_config} -E #{rails_env} -D || ( tail -100 #{current_path}/log/unicorn.errors ; exit 1 )"
      else
        logger.info "Unicorn already started. Doing nothing."
      end
    end

    desc "Gracefully stop unicorn from serving requests"
    task :stop, :roles => [:app], :except => { :no_release => true } do
      if pid_is_running?(unicorn_pid)
        run "#{sudo} kill -QUIT `cat #{unicorn_pid}`; #{sudo} rm #{unicorn_pid}"
        unicorn.tail.stop
      else
        logger.info "Unicorn is not running. Doing nothing."
      end
    end

    desc "Update unicorn without dropping any connections"
    task :upgrade, :roles => [:app], :except => { :no_release => true } do
      sudo "kill -USR2 `cat #{unicorn_pid}`"
    end

    desc "Start or upgrade unicorn"
    namespace :restart do
      task :default do
        if get_servers(self, :role => :app, :except => { :no_release => true}).size > 0
          unicorn.restart.on_servers
        end
      end
      task :on_servers, :roles => [:app], :except => { :no_release => true } do
        if pid_is_running?(unicorn_pid)
          unicorn.upgrade
        else
          unicorn.start
        end
      end
    end

    desc "Reopen log files"
    task :reopen_logs, :roles => [:app], :except => { :no_release => true } do
      sudo "kill -USR1 `cat #{unicorn_pid}`"
    end

    namespace :confirm do
      task :stop, :roles => [:app], :except => { :no_release => true } do
        pid = capture("ps -ef | grep unicorn | grep -v grep | grep master | awk '{print $2 }'").chomp
        run "while [ `ps -ef | grep unicorn | grep -v grep | grep master | awk '{ print $2 }'` -eq #{pid} ] ; do sleep 1; done ;"
      end
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
end
