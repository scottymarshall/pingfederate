
include_recipe 'pingfederate::prerequisites'

full_path = "#{node['pingfed']['install_dir']}/#{node['pingfed']['filename']}"

user 'pingfederate' do
  shell '/bin/bash'
  action :create
  manage_home true
end

remote_file 'pingfederate' do
  source node['pingfed']['download_url']
  path File.join(Chef::Config[:file_cache_path], "#{node['pingfed']['filename']}.tar.gz")
  owner node['pingfed']['user']
  group node['pingfed']['user']
  action :create
end

execute 'pingfederate untar' do
  command "tar xzf #{File.join(Chef::Config[:file_cache_path], "#{node['pingfed']['filename']}.tar.gz")}"
  cwd node['pingfed']['install_dir']
  action :run
  not_if { ::File.exist?(full_path.to_s) }
end

execute 'change permissions' do
  command "chown -R #{node['pingfed']['user']}.#{node['pingfed']['user']} #{full_path}"
  action :run
end

link node['pingfed']['symbolic_install_path'] do
  to "#{full_path}/pingfederate"
  link_type :symbolic
  action :create
  notifies :restart, 'service[pingfederate]', :delayed
end

template "#{full_path}/pingfederate/bin/run.properties" do
  source 'run_properties.erb'
  owner node['pingfed']['user']
  group node['pingfed']['user']
  variables(
    admin_port: '9999',
    bind_address: '0.0.0.0',
    listen_port: '9031',
    mode: 'STANDALONE'
  )
  action :create
  notifies :restart, 'service[pingfederate]', :delayed
end

template "#{full_path}/pingfederate/bin/run.sh" do
  source 'run_sh.erb'
  owner node['pingfed']['user']
  group node['pingfed']['user']
  variables(
    java_home: node['pingfed']['java_home']
  )
  action :create
  notifies :restart, 'service[pingfederate]', :delayed
end

template "#{full_path}/pingfederate/sbin/pingfederate-run.sh" do
  source 'pingfederate_run_sh.erb'
  owner node['pingfed']['user']
  group node['pingfed']['user']
  mode 0744
  action :create
  notifies :restart, 'service[pingfederate]', :delayed
end

template '/etc/init.d/pingfederate' do
  source 'init.erb'
  mode '0755'
  action :create
  notifies :restart, 'service[pingfederate]', :delayed
end

systemd_service 'pingfederate' do
  description 'Pingfederate Applications'
  after %w( network.target syslog.target )
  install do
    wanted_by 'multi-user.target'
  end
  service do
    exec_stop File.join(node['pingfed']['sbin_dir'], 'pingfederate-shutdown.sh')
    exec_start File.join(node['pingfed']['sbin_dir'], 'pingfederate-run.sh')
    pid_file File.join(node['pingfed']['bin_dir'], 'pingfederate.pid')
    user node['pingfed']['user']
    group node['pingfed']['user']
    type 'forking'
  end
  only_if { `rpm -qa | grep systemd` != '' } # systemd
end

execute 'RESTART_WAIT_180' do
  command 'sleep 180'
  action :nothing
end

service 'pingfederate' do
  action :enable
end

service 'pingfederate' do
  action :start
  notifies :run, 'execute[RESTART_WAIT_180]', :immediately
end
