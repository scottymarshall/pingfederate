# install.rb

actions :install, :remove
default_action :install

attribute :server_type, kind_of: String, default: "standalone"
attribute :cluster_port, kind_of: Integer, default: node['pingfed']['default_cluster_bind_port']
attribute :cluster_node_index, kind_of: Integer

def initialize(*args)
  super
end