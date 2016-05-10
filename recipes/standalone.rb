
include_recipe 'pingfederate::prerequisites'

full_path = "#{node['pingfed']['install_dir']}/#{node['pingfed']['filename']}"

user 'pingfederate' do
  shell '/bin/bash'
  action :create
end

remote_file 'pingfederate' do
  source node['pingfed']['download_url']
  path File.join(Chef::Config[:file_cache_path],"#{node['pingfed']['filename']}.tar.gz")
  owner node['pingfed']['user']
  group node['pingfed']['user']
  action :create
end

execute 'pingfederate untar' do
  command "tar xzf #{File.join(Chef::Config[:file_cache_path],"#{node['pingfed']['filename']}.tar.gz")}"
  cwd node['pingfed']['install_dir']
  action :run
  not_if { ::File.exist?("#{full_path}") }
end

execute 'change permissions' do
  command "chown -R #{node['pingfed']['user']}.#{node['pingfed']['user']} #{full_path}"
  action :run
end

link '/usr/local/pingfederate' do 
  to "#{full_path}/pingfederate"
  link_type :symbolic
  action :create
  notifies :restart, "service[pingfederate]", :delayed
end

template "#{full_path}/pingfederate/bin/run.properties" do
  source 'run_properties.erb'
  owner node['pingfed']['user']
  group node['pingfed']['user']
  variables(
   :admin_port => '9999',
   :bind_address => '0.0.0.0',
   :listen_port => '9031',
   :mode => 'STANDALONE'
  )
  action :create
  notifies :restart, "service[pingfederate]", :delayed
end

template "#{full_path}/pingfederate/bin/run.sh" do
  source 'run_sh.erb'
  owner node['pingfed']['user']
  group node['pingfed']['user']
  variables(
   :java_home => node['pingfed']['java_home']
  )
  action :create
  notifies :restart, "service[pingfederate]", :delayed
end


template "#{full_path}/pingfederate/sbin/pingfederate-run.sh" do
  source 'pingfederate_run_sh.erb'
  owner node['pingfed']['user']
  group node['pingfed']['user']
  mode 0744
  action :create 
  notifies :restart, "service[pingfederate]", :delayed
end

# template '/usr/local/pingfederate-8.1.1/pingfederate/bin/run.sh' do
  # source 'run_sh.erb'
  # owner 'pingfederate'
  # group 'pingfederate'
  # mode 0744
  # variables(
   # :java_home => JmhJavaUtil.get_java_home(new_resource.java_version, node)
  # )
  # action :create
# end

template '/etc/init.d/pingfederate' do
  source 'init.erb'
  mode '0755'
  action :create
  notifies :restart, "service[pingfederate]", :delayed
end

service 'pingfederate' do
  action [:enable]
end


