pingfederate cookbook
=======

This book installs the Pingfederate server 

Usage
-------
Simply include the `pingfederate:standalone` recipe wherever you would like pingfederate installed, such as a run list (`recipe[pingfederate]`). 
By default, the STANDALONE version is installed. 

Examples
========

Requirements
============
Chef 12+

### Platform
* CentOS, RHEL

### Coobooks
* `java`

Attributes
==========
* `node['pingfed']['install_dir']` - Install location, defaults to `/usr/local`
* `node['pingfed']['java_home']` = Java Home for java running pingfederate, defaults to `node['java']['java_home']`
* `node['pingfed']['version']` = '8.4.0'
* `node['pingfed']['user']` = 'pingfederate'
* `node['pingfed']['admin_user']` = 'Administrator'
* `node['pingfed']['admin_password']` = 'Some Password you manually set'
* `node['pingfed']['base_url']` = 'https://yourserverdomain.com'
* `node['pingfed']['saml2_entry_id']` = 'your_pingfed_serverid'


Recipes
=======

### default 

Installs `standalone` version of pingfederate

### standalone

Installs `standalone` version of pingfederate

### oauth_settings

Configures basic server settings via API calls, not called by default
* FIRST time this cookbook is run it will not create the configuration as Pingfederate requires
  manuall intervention to create a user and password and set some default install parameters
* SECOND time this cookbook runs, it will create the server_settings configuration from what you provide
  and can be validated via API calls to https://localhost:9999/pf-admin-api/v1/serverSettings

Author
======

* Author: Scott Marshall (scott.marshall@johnmuirhealth.com)
* Author: Melinda Moran (melinda.moran@johnmuirhealth.com)
