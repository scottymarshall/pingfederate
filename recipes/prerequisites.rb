include_recipe 'java'

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