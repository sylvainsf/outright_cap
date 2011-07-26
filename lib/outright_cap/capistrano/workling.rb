Capistrano::Configuration.instance(:must_exist).load do
  namespace :workling do
    desc "Status of workling processes and their jobs"
    task :status, :roles => :workling do
      run "ps -ef | grep '[w]orkling[^_]' | awk '{ print $2 }' | while read a ; do { cat #{current_path}/log/agg_director.log | grep '\[$a\]' | tail -n 1 | grep -v finished ; true ; } done"
    end

    desc "Start workling processes"
    task :start, :roles => :workling do
      workling.start_general_worklings        if get_servers(self, :role => :workling, :queue => "general").size > 0
      workling.start_manual_import_worklings  if get_servers(self, :role => :workling, :queue => "manual_import").size > 0
    end

    desc "Stop workling processes"
    task :stop, :roles => :workling do
      run "cd #{current_path}; export RAILS_ENV=#{rails_env}; script/workling_client stop"
    end

    desc "Recover workling jobs"
    task :recover, :roles => :workling_recover do
      1.upto(10) do |i|
        run("ps -ef | grep workling | grep -v grep | wc -l", :roles => [:workling]) do |channel, stream, data|
          break if data.to_i == 0
          raise "Workling processes are still running on #{channel[:host]}" if (data.to_i > 0 && i == 10)
        end
        sleep(5)
      end
      run "cd #{current_path}; export RAILS_ENV=#{rails_env}; script/workling_recover"
    end

    desc "Kill workling processes"
    task :kill, :roles => :workling do
      run "ps -ef | grep workling | awk '{print $2}' | xargs kill -9;"
    end

    desc "Restart workling processes"
    task :restart, :roles => :workling do
      workling.stop
      workling.start
    end

    task :start_general_worklings, :roles => :workling, :only => { :queue => 'general' } do
      number_worklings.times do
        queues = [
          "deferred_method_workers__process"
        ]

        run "cd #{current_path}; export RAILS_ENV=#{rails_env}; export QUEUES=#{queues.join(":")}; script/workling_client start"
      end
    end

    task :start_manual_import_worklings, :roles => :workling, :only => { :queue => 'manual_import' } do
      number_worklings.times do
        run "cd #{current_path}; export RAILS_ENV=#{rails_env}; export MAX_PRIORITY=0; export QUEUES=deferred_method_workers__process; script/workling_client start"
      end
    end
  end
end
