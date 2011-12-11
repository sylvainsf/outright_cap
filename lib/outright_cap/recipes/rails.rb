Capistrano::Configuration.instance(:must_exist).load do
  namespace :rails do
    namespace :assets do
      desc <<-DESC
        Run the asset precompilation rake task. You can specify the full path \
        to the rake executable by setting the rake variable. You can also \
        specify additional environment variables to pass to rake via the \
        asset_env variable. The defaults are:

          set :rake,      "rake"
          set :rails_env, "production"
          set :asset_env, "RAILS_GROUPS=assets"
      DESC
      task :precompile, :roles => :web, :except => { :no_release => true } do
        run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} assets:precompile"
      end
    end
  end
  before 'deploy:finalize_update', 'rails:assets:precompile'
end
