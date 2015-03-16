Chef::Recipe.send(:include, CloudConductor::CommonHelper)
Chef::Resource.send(:include, CloudConductor::CommonHelper)
Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)
Chef::Resource.send(:include, CloudConductor::AmandaPartHelper)

parameters = CloudConductorUtils::Consul.read_parameters[:cloudconductor]
hosts_paths_privileges_under_role(parameters).each do |role, role_host_backup_restore_config|
  role_host_backup_restore_config[:paths].each do |path_config|
    config = amanda_config(role, path_config[:path])
    bash "amdump_#{config[:name]}" do
      code <<-EOS
        su - #{node['amanda_part']['user']} -c "amcheck #{config[:name]} | grep 'Could not access .*: No such file or directory'"
        if [ $? == 0 ]; then
          exit 0
        else
          su - #{node['amanda_part']['user']} -c "amdump #{config[:name]}"
        fi
      EOS
      only_if { amanda_server? }
    end
  end
end
