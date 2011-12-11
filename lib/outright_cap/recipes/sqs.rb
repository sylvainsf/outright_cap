Capistrano::Configuration.instance(:must_exist).load do
  namespace :sqs do
    desc "Show the number of items on each queue"
    task :status, :roles => :workling do
      run "export RAILS_ENV=#{rails_env}; cd #{current_path}; bundle exec ruby script/sqs_status.rb", :once => true
    end
  end
end
