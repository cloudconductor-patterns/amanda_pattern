Chef::Recipe.send(:include, CloudConductor::CommonHelper)
Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)

amandahosts = File.join(node['amanda_part']['amanda_data_dir'], '.amandahosts')
amanda_server_info = amanda_server
template amandahosts do
  owner node['amanda_part']['user']
  group node['amanda_part']['group']
  source '.amandahosts-server.erb'
  mode 0600
  variables(
    amanda_server: amanda_server_info,
    amanda_clients: CloudConductorUtils::Consul.read_servers
  )
end

parameters = CloudConductorUtils::Consul.read_parameters[:cloudconductor]
hosts_paths_privileges_under_role(parameters).each do |role, role_host_backup_restore_config|
  role_host_backup_restore_config[:paths].each do |path_config|
    config = amanda_config(role, path_config[:path])
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
        not_if { File.exist?(dir) }
      end
    end

    disklist = File.join(config[:config_dir], 'disklist')
    template disklist do
      owner node['amanda_part']['user']
      group node['amanda_part']['group']
      source 'disklist.erb'
      mode 0644
      variables(
        hosts: role_host_backup_restore_config[:hosts],
        path_config: path_config
      )
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
    end

    cron_conf = File.join('/etc/cron.d', config[:name])
    template cron_conf do
      owner 'root'
      source 'cron.erb'
      mode 0644
      variables(
        config_name: config[:name],
        schedule: path_config[:schedule]
      )
    end
  end
end
