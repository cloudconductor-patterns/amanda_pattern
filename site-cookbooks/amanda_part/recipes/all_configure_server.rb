Chef::Recipe.send(:include, CloudConductor::CommonHelper)
Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)

parameters = CloudConductorUtils::Consul.read_parameters[:cloudconductor]
roles = ENV['ROLE'].nil? ? [] : ENV['ROLE'].split(',')
hosts_paths_privileges_by_role(roles, parameters).each do |role, role_config|
  role_config[:paths].each do |path_config|
    amanda_config(role, path_config[:path])
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