include_recipe 'pingfederate::prerequisites'
include_recipe 'pingfederate::cluster_prerequisites'

service 'pingfederate-engine'

pingfederate_install "engine" do
  server_type "engine"
end

