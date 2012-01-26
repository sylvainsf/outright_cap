Capistrano::Configuration.instance(:must_exist).load do
  namespace :thrift do
    desc "Start thrift server"
    task :start, :roles => :thrift do
      run "#{sudo} /etc/init.d/thrift_server start"
    end

    desc "Stop thrift server"
    task :stop, :roles => :thrift do
      run "#{sudo} /etc/init.d/thrift_server stop"
    end

    desc "Restart thrift server"
    task :restart, :roles => :thrift do
      run "#{sudo} /etc/init.d/thrift_server restart"
    end
  end
end
