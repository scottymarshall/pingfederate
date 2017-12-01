
default['java']['jdk_version'] = '8'
default['java']['install_flavor'] = 'oracle'
default['java']['oracle']['accept_oracle_download_terms'] = true


default['pingfed']['install_dir'] = '/usr/local'
default['pingfed']['symbolic_install_path'] = File.join(node['pingfed']['install_dir'],'pingfederate') 
default['pingfed']['java_home'] = node['java']['java_home']
default['pingfed']['version'] = '8.1.1'
default['pingfed']['filename'] = "pingfederate-" + node['pingfed']['version']
default['pingfed']['download_url'] = "https://s3.amazonaws.com/pingone/public_downloads/pingfederate/" + 
                                      node['pingfed']['version'] + "/" + node['pingfed']['filename'] + ".tar.gz"
default['pingfed']['user'] = 'pingfederate'
                                      
# Used for default oauth_settings recipe
default['pingfed']['base_url'] = 'https://yourserverdomain.com'
default['pingfed']['saml2_entry_id'] = 'yourpingfedserverid'
default['pingfed']['admin_user'] = 'Administrator'
default['pingfed']['admin_password'] = 'YourPassword'
