amandahosts = File.join(node['amanda_part']['amanda_data_dir'], '.amandahosts')
template amandahosts do
  owner node['amanda_part']['user']
  group node['amanda_part']['group']
  source '.amandahosts-server.erb'
  mode 0600
  variables(
    amanda_server_name: amanda_server_name,
    amanda_clients: CloudConductorUtils::Consul.read_servers
  )
  only_if { server? }
end

host_config.each do |hostname, backup_restore_config|
  backup_restore_config[:paths].each do |path_config|
    config = amanda_config(hostname, path_config[:path])
    [
      node['amanda_part']['amanda_dir'],
      node['amanda_part']['amanda_config_dir'],
      config[:config_dir],
      config[:vtapes_dir],
      config[:holding_dir],
      config[:info_dir],
      config[:log_dir],
      config[:index_dir],
      *config[:slot_dirs]
    ].each do |dir|
      directory dir do
        owner node['amanda_part']['user']
        group node['amanda_part']['group']
        mode 0755
        recursive true
        action :create
        only_if { server? && !File.exist?(dir) }
      end
    end

    disklist = File.join(config[:config_dir], 'disklist')
    template disklist do
      owner node['amanda_part']['user']
      group node['amanda_part']['group']
      source 'disklist.erb'
      mode 0644
      variables(
        hostname: hostname,
        path_config: path_config
      )
      only_if { server? }
    end

    amanda_conf = File.join(config[:config_dir], 'amanda.conf')
    template amanda_conf do
      owner node['amanda_part']['user']
      group node['amanda_part']['group']
      source 'amanda.conf.erb'
      mode 0644
      variables(
        config: config,
        path_config: path_config
      )
      only_if { server? }
    end

    cron_conf = File.join('/etc/cron.d', config[:name])
    template cron_conf do
      owner node['amanda_part']['execuser']
      source 'cron.erb'
      mode 0644
      variables(
        config_name: config[:name],
        schedule: path_config[:schedule]
      )
      only_if { server? }
    end
  end
end
