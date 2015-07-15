Chef::Recipe.send(:include, CloudConductor::CommonHelper)
Chef::Resource.send(:include, CloudConductor::CommonHelper)
Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)
Chef::Resource.send(:include, CloudConductor::AmandaPartHelper)

remote_file "#{Chef::Config[:file_cache_path]}/amanda-backup_client-3.3.6-1.rhel6.x86_64.rpm" do
  source 'http://www.zmanda.com/downloads/community/Amanda/3.3.6/Redhat_Enterprise_6.0/amanda-backup_client-3.3.6-1.rhel6.x86_64.rpm'
  notifies :install, 'yum_package[amanda-backup_client]', :immediately
end

yum_package 'amanda-backup_client' do
  source "#{Chef::Config[:file_cache_path]}/amanda-backup_client-3.3.6-1.rhel6.x86_64.rpm"
  action :nothing
end

service 'xinetd' do
  supports status: true, restart: true, reload: true
  action :nothing
end

cookbook_file '/etc/xinetd.d/amandaclient' do
  owner node['amanda_part']['user']
  group node['amanda_part']['group']
  source 'amandaclient'
  mode 0644
  notifies :restart, 'service[xinetd]', :immediate
end

directory node['amanda_part']['amanda_data_dir'] do
  owner node['amanda_part']['user']
  group node['amanda_part']['group']
  mode 0755
  recursive true
  action :create
  not_if { File.exist?(node['amanda_part']['amanda_data_dir']) }
end

amandahosts_client = File.join(node['amanda_part']['amanda_data_dir'], '.amandahosts')
template amandahosts_client do
  owner node['amanda_part']['user']
  group node['amanda_part']['group']
  source '.amandahosts-client.erb'
  mode 0600
  variables(
    amanda_server: amanda_server
  )
end

parameters = node[:cloudconductor]
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
      directory path_config[:path] do
        owner node['amanda_part']['user']
        group node['amanda_part']['group']
        mode 0777
        recursive true
        action :create
        only_if { path_config[:prepare_path] && !File.exist?(path_config[:path]) }
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
