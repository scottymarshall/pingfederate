#
# Copyright (c) 2017 The Authors, All Rights Reserved.
#
# Cookbook Name:: pingfederate
# Recipe:: oauth_settings
# Description:: setup settings for PingFederate via API calls
#

base_curl="curl -u #{node['pingfed']['admin_user']}:#{node['pingfed']['admin_password']} -k -H \"X-XSRF-Header: PingFederate\" " 

### Server Settings - /serverSettings
# PUT
server_settings=File.join(Chef::Config[:file_cache_path],'server_settings.json')

template server_settings do
  source 'server_settings.erb'
  mode 0600
  action :create
  variables(
    :idp_base_url => node['pingfed']['base_url'],
    :saml2_entry_id =>  node['pingfed']['saml2_entry_id']
  ) 
end

# execute with option "live_stream true" will allow for command to be shown
execute "server_settings" do
  command "#{base_curl} -H \"Content-Type: application/json\" -X PUT -d @#{server_settings} https://localhost:9999/pf-admin-api/v1/serverSettings"
  live_stream true
  action :run      
end
