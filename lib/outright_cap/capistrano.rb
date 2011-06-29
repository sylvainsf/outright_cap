Capistrano::Configuration.instance(:must_exist).load do
  namespace :outright do
    desc "Testing"
    task :test do
      puts "Testing outright_cap gem"
    end
  end
end
