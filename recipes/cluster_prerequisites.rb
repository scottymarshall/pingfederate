# Create the Cluster host array

cluster_initial_hosts = Array.new
if node['pingfed']['cluster_host_array_override']
  node.default['pingfed']['cluster_host_array'] = node['pingfed']['cluster_host_array_override']
else
  search(:node, 'recipes:pingfederate\:\:console_instance') do |n|
    cluster_initial_hosts.push("#{n['ipaddress']}[#{node['pingfed']['console_cluster_bind_port']}]")
  end
  search(:node, 'recipes:pingfederate\:\:engine_instance') do |n|
    cluster_initial_hosts.push("#{n['ipaddress']}[#{node['pingfed']['default_cluster_bind_port']}]")
  end

  Chef::Log.warn("The Cluster hosts list is: #{cluster_initial_hosts.to_s}")

  node.default['pingfed']['cluster_host_array'] = cluster_initial_hosts.nil? ? Array.new : cluster_initial_hosts
end
