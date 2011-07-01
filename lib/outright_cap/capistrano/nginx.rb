Capistrano::Configuration.instance(:must_exist).load do
  namespace :nginx do
    desc "Restart the nginx process"
    task :restart, :roles => [:web], :except => { :no_release => true } do
      sudo "/etc/init.d/nginx restart"
    end

    desc "Start the nginx process"
    task :start, :roles => [:web], :except => { :no_release => true } do
      sudo "/etc/init.d/nginx start"
    end

    desc "Stop the nginx process"
    task :stop, :roles => [:web], :except => { :no_release => true } do
      sudo "/etc/init.d/nginx stop"
    end
  end
end
