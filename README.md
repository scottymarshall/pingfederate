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

Recipes
=======

### default 

Installs `standalone` version of pingfederate

### standalone

Installs `standalone` version of pingfederate

Author
======

* Author: Scott Marshall (scott.marshall@johnmuirhealth.com)
