use_inline_resources

action :install do
  key = new_resource.server_type

  standalone = (key == 'standalone') ? true : false
  operational_mode = case key
                     when "console"
                       "CLUSTERED_CONSOLE"
                     when "engine"
                       "CLUSTERED_ENGINE"
                     else
                       "STANDALONE"
                     end

  install_dir = (standalone) ? node['pingfed']['install_dir'] : ::File.join(node['pingfed']['install_dir'], "pingfederate-#{key}")
  service_name = (standalone) ? 'pingfederate' : "pingfederate-#{key}"
  symbolic_link = (standalone) ? node['pingfed']['symbolic_install_path'] : ::File.join(node['pingfed']['install_dir'], service_name,"pingfederate")
  full_path = ::File.join(install_dir,node['pingfed']['filename'])
  sbin_dir = ::File.join(install_dir, node['pingfed']['filename'], 'pingfederate','sbin')

  directory install_dir do
    owner node['pingfed']['user']
    group node['pingfed']['user']
    mode 0755
    action :create
    not_if { standalone }
  end

  execute 'pingfederate untar' do
    command "tar xzf #{::File.join(Chef::Config[:file_cache_path], "#{node['pingfed']['filename']}.tar.gz")}"
    cwd install_dir
    action :run
    not_if { ::File.exist?(full_path.to_s) }
  end

  execute 'change permissions' do
    command "chown -R #{node['pingfed']['user']}.#{node['pingfed']['user']} #{full_path}"
    action :run
  end

  Chef::Log.warn("Symbolic Link location will be #{symbolic_link}")

  link symbolic_link do
    to "#{full_path}/pingfederate"
    link_type :symbolic
    action :create
    notifies :restart, "service[#{service_name}]", :delayed
  end


  template "#{full_path}/pingfederate/bin/run.properties" do
    source 'run_properties.erb'
    owner node['pingfed']['user']
    group node['pingfed']['user']
    variables(
        admin_port: node['pingfed']['admin_port'],
        bind_address: node['pingfed']['bind_address'],
        listen_port: node['pingfed']['listen_port'],
        mode: operational_mode,
        cluster_node_index: new_resource.cluster_node_index,
        cluster_password: node['pingfed']['cluster_password'],
        cluster_failure_port: node['pingfed']['cluster_failure_detection_bind_port'],
        cluster_encrypt: true,
        cluster_bind_address: 'NON_LOOPBACK',
        cluster_bind_port: new_resource.cluster_port,
        cluster_initial_hosts: node['pingfed']['cluster_host_array'].to_a.compact.reject(&:empty?).join(',')
    )
    action :create
    notifies :restart, "service[#{service_name}]", :delayed
  end

  template "#{full_path}/pingfederate/bin/run.sh" do
    cookbook node['pingfed']['run_template_cookbook']
    source 'run_sh.erb'
    owner node['pingfed']['user']
    group node['pingfed']['user']
    variables(
        java_home: node['pingfed']['java_home']
    )
    action node['pingfed']['run_template']['action']
    notifies :restart, "service[#{service_name}]", :delayed
  end

  template "#{full_path}/pingfederate/sbin/pingfederate-run.sh" do
    cookbook node['pingfed']['run_template']['cookbook']
    source 'pingfederate_run_sh.erb'
    owner node['pingfed']['user']
    group node['pingfed']['user']
    mode 0744
    action node['pingfed']['run_template']['action']
    variables(
        java_home: node['pingfed']['java_home']
    )
    notifies :restart, "service[#{service_name}]", :delayed
  end

  template "/etc/init.d/#{service_name}" do
    source 'init.erb'
    mode '0755'
    action :create
    variables(
      sbin_dir: sbin_dir,
      service_name: service_name
    )
  end

  systemd_service service_name do
    description 'Pingfederate Applications'
    after %w( network.target syslog.target )
    install do
      wanted_by 'multi-user.target'
    end
    service do
      exec_stop ::File.join(sbin_dir, 'pingfederate-shutdown.sh')
      exec_start ::File.join(sbin_dir, 'pingfederate-run.sh')
      user node['pingfed']['user']
      group node['pingfed']['user']
      type 'forking'
    end
    only_if { `rpm -qa | grep systemd` != '' } # systemd
  end

  ruby_block 'PortOpen' do
    block do
      sleep 10
      Chef::Application.fatal!("Port is not open") unless PingfedHelper.port_open?('localhost',9999, 10, 18)
    end
    action :nothing
  end

  service service_name do
    action [:enable, :start]
    notifies :run, 'ruby_block[PortOpen]', :delayed
  end
end