default['pingfed']['admin_port'] = 9999
default['pingfed']['listen_port'] = 9031
default['pingfed']['bind_address'] = '0.0.0.0'
default['pingfed']['default_cluster_bind_port'] = 7600
default['pingfed']['console_cluster_bind_port'] = 7610
default['pingfed']['cluster_failure_detection_bind_port'] = 7700
default['pingfed']['cluster_password'] = '123456789012345678901234567890'

default['pingfed']['operational_mode']['standalone'] = 'STANDALONE'

default['pingfed']['install_dir'] = '/usr/local'
default['pingfed']['symbolic_install_path'] = File.join(node['pingfed']['install_dir'], 'pingfederate')
default['pingfed']['java_home'] = '/usr/lib/jvm/java'
default['pingfed']['version'] = '9.2.2'
default['pingfed']['filename'] = 'pingfederate-' + node['pingfed']['version']
default['pingfed']['download_url'] = 'https://s3.amazonaws.com/pingone/public_downloads/pingfederate/' +
                                     node['pingfed']['version'] + '/' + node['pingfed']['filename'] + '.tar.gz'
default['pingfed']['user'] = 'pingfederate'
default['pingfed']['run_template']['cookbook'] = 'pingfederate'
default['pingfed']['run_template']['action'] = :create

default['pingfed']['sbin_dir'] = File.join(node['pingfed']['install_dir'], node['pingfed']['filename'], 'pingfederate','sbin')
default['pingfed']['bin_dir'] = File.join(node['pingfed']['install_dir'], node['pingfed']['filename'], 'pingfederate','bin')

# Used for oauth_settings recipe
default['pingfed']['base_url'] = 'https://yourserverdomain.com'
default['pingfed']['saml2_entry_id'] = 'yourpingfedserverid'
default['pingfed']['admin_user'] = 'Administrator'
default['pingfed']['admin_password'] = 'YourPassword'
