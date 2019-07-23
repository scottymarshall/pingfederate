
include_recipe 'pingfederate::prerequisites'

service 'pingfederate'

pingfederate_install "standalone" do
  server_type "standalone"
end

