Capistrano::Configuration.instance(:must_exist).load do
  namespace :apt do
    desc "Install certain apt packages"
    task :install do
      install_package("ca-certificates")
    end
  end

  def install_package(name)
    run "dpkg -l | grep #{name} || #{sudo} aptitude install -y #{name}", :shell => "sh"
  end
  
  after "deploy:setup", "apt:install"
end
