Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    desc <<-DESC
      Run the migrate rake task. By default, it runs this in most recently \
      deployed version of the app. However, you can specify a different release \
      via the migrate_target variable, which must be one of :latest (for the \
      default behavior), or :current (for the release indicated by the \
      `current' symlink). Strings will work for those values instead of symbols, \
      too. You can also specify additional environment variables to pass to rake \
      via the migrate_env variable. Finally, you can specify the full path to the \
      rake executable by setting the rake variable. The defaults are:

        set :rake,           "rake"
        set :rails_env,      "production"
        set :migrate_env,    ""
        set :migrate_target, :latest
    DESC
    task :migrate, :roles => :migrator do
      migrate_env = fetch(:migrate_env, "")
      migrate_target = fetch(:migrate_target, :latest)

      directory = case migrate_target.to_sym
        when :current then current_path
        when :latest  then latest_release
        else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
        end

      run "cd #{directory} && #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate", :once => true
    end
  end

  after "deploy", "deploy:cleanup"
  after "deploy:migrate", "deploy:restart"

  namespace :deploy do
    namespace :web do
      desc <<-DESC
        Present a maintenance page to visitors. Disables your application's web \
        interface by linking public/#{maintenance_basename}.html to \
        public/system/#{maintenance_basename}.html.
      DESC
      task :disable, :roles => :web, :except => { :no_release => true } do
        on_rollback { run "rm #{shared_path}/system/#{maintenance_basename}.html" }
        run "ln -s #{deploy_to}/current/public/#{maintenance_basename}.html #{shared_path}/system/#{maintenance_basename}.html"
      end

      desc <<-DESC
        Makes the application web-accessible again. Removes the symbolic link \
        to public/system/#{maintenance_basename}.html".
      DESC
      task :enable, :roles => :web, :except => { :no_release => true } do
        run "rm #{shared_path}/system/#{maintenance_basename}.html"
      end
    end
  end
end
