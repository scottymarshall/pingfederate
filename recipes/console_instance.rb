include_recipe 'pingfederate::prerequisites'
include_recipe 'pingfederate::cluster_prerequisites'

service 'pingfederate-console'

pingfederate_install "console" do
  server_type "console"
  cluster_port node['pingfed']['console_cluster_bind_port']
end

