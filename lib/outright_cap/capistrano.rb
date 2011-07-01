Capistrano::Configuration.instance(:must_exist).load do
  _cset :bundler_version, '1.0.10'
  _cset(:unicorn_config) { "#{current_path}/config/unicorn.rb" }
  _cset(:unicorn_pid) { "#{shared_path}/pids/unicorn.pid" }

  after "workling:stop", "workling:recover"

  def pid_is_running?(full_path)
    "0" == capture("if [ -f #{full_path} ] ; then cat #{full_path} | xargs sudo kill -0 ; echo $? ; fi ;").strip
  end

  def get_servers(deploy_context, options)
    if (role = options[:role] )
      servers = deploy_context.parent.roles[role].servers
    elsif roles = options[:roles]
      servers = deploy_context.parent.roles.map{|role_name, role|
        roles.include?(role_name) ? role.servers : []
      }.flatten
    else
      servers = deploy_context.parent.roles.map{|role_name, role| role.servers}.flatten
    end

    if (queue = options[:queue])
      queue_servers = []
      queues = queue.kind_of?(Enumerable) ? queue : [queue]
      queues.each do |queue_name|
        queue_servers += servers.select { |server| server.options[:queue] == queue_name }
      end
      servers = queue_servers
    end

    servers
  end

  def install_gem(name, options = {})
    version = options[:version]
    gem_cmd = "gem"

    if options[:source]
      source = "--source #{options[:source]}"
    end

    if version
      run "#{gem_cmd} list | grep '#{name}' | grep '#{version}' || #{sudo} #{gem_cmd} install #{name} #{source} --version '= #{version}' --no-rdoc --no-ri"
    else
      run "#{gem_cmd} list | grep '#{name}' || #{sudo} #{gem_cmd} install #{name} #{source} --no-rdoc --no-ri"
    end
  end
end

require 'outright_cap/capistrano/apt'
require 'outright_cap/capistrano/sqs'
require 'outright_cap/capistrano/unicorn'
require 'outright_cap/capistrano/workling'
require 'outright_cap/capistrano/nginx'
