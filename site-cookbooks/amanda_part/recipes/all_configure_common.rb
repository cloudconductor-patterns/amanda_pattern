Chef::Recipe.send(:include, CloudConductor::CommonHelper)
Chef::Resource.send(:include, CloudConductor::CommonHelper)
Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)
Chef::Resource.send(:include, CloudConductor::AmandaPartHelper)

parameters = node['cloudconductor']
roles = ENV['ROLE'].nil? ? [] : ENV['ROLE'].split(',')
hosts_paths_privileges_by_role(roles, parameters).each do |role, role_config|
  role_config[:paths].each do |path_config|
    config = amanda_config(role, path_config[:path])
    directory config[:config_dir] do
      owner node['amanda_part']['user']
      group node['amanda_part']['group']
      mode 0755
      recursive true
      action :create
      not_if { File.exist?(config[:config_dir]) }
    end
    directory path_config[:path] do
      owner node['amanda_part']['user']
      group node['amanda_part']['group']
      mode 0777
      recursive true
      action :create
      only_if { path_config[:prepare_path] && !File.exist?(path_config[:path]) }
    end
    amanda_client_conf = File.join(config[:config_dir], 'amanda-client.conf')
    template amanda_client_conf do
      owner node['amanda_part']['user']
      group node['amanda_part']['group']
      source 'amanda-client.conf.erb'
      mode 0644
      variables(
        amanda_server: amanda_server,
        config: config
      )
    end
    path_config[:scripts].each do |script_name, script_config|
      script_path = File.join(node['amanda_part']['client']['script_dir'], script_name)
      template script_path do
        owner node['amanda_part']['user']
        group node['amanda_part']['group']
        source 'script.erb'
        mode 0755
        variables(
          script: script_config[:script]
        )
      end
    end
  end
  template "/etc/sudoers.d/backup_restore_#{role}" do
    owner 'root'
    group 'root'
    source 'sudoers.erb'
    mode 0600
    variables(
      hostname: node['hostname'],
      privileges_config: role_config[:privileges]
    )
  end
end
