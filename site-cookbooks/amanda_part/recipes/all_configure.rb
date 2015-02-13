require 'cloud_conductor_utils/consul'
roles = ENV['ROLE'].strip.split(',')

remote_file "#{Chef::Config[:file_cache_path]}/amanda-backup_client-3.3.6-1.rhel6.x86_64.rpm" do
  source 'http://www.zmanda.com/downloads/community/Amanda/3.3.6/Redhat_Enterprise_6.0/amanda-backup_client-3.3.6-1.rhel6.x86_64.rpm'
  notifies :install, 'yum_package[amanda-backup_client]', :immediately
  not_if { roles.include?('backup')  }
end

yum_package 'amanda-backup_client' do
  source "#{Chef::Config[:file_cache_path]}/amanda-backup_client-3.3.6-1.rhel6.x86_64.rpm"
  action :nothing
  not_if { roles.include?('backup') }
end

cookbook_file '/etc/xinetd.d/amandaclient' do
  owner node['amanda_part']['client']['dumpuser']
  group node['amanda_part']['client']['dumpusergroup']
  source 'amandaclient'
  mode 0644
end

directory node['amanda_part']['client']['var_amanda_dir'] do
  owner node['amanda_part']['client']['dumpuser']
  group node['amanda_part']['client']['dumpusergroup']
  mode 0755
  recursive true
  action :create
  not_if { File.exist?(node['amanda_part']['client']['var_amanda_dir']) }
end

server = server_info('backup').first
amandahosts_client = File.join(node['amanda_part']['client']['var_amanda_dir'], '.amandahosts')
template amandahosts_client do
  owner node['amanda_part']['client']['dumpuser']
  group node['amanda_part']['client']['dumpusergroup']
  source '.amandahosts-client.erb'
  mode 0644
  variables(
    server: server
  )
  not_if { roles.include?('backup') }
end

directory node['amanda_part']['client']['config_dir'] do
  owner node['amanda_part']['client']['dumpuser']
  group node['amanda_part']['client']['dumpusergroup']
  mode 0755
  recursive true
  action :create
  not_if { File.exist?(node['amanda_part']['client']['config_dir']) }
end

server = server_info('backup').first
amanda_client_conf = File.join(node['amanda_part']['client']['config_dir'], 'amanda-client.conf')
template amanda_client_conf do
  owner node['amanda_part']['client']['dumpuser']
  group node['amanda_part']['client']['dumpusergroup']
  source 'amanda-client.conf.erb'
  mode 0644
  variables(
    server: server[:hostname]
  )
  not_if { roles.include?('backup') }
end

directory node['amanda_part']['client']['script_dir'] do
  owner node['amanda_part']['client']['dumpuser']
  group node['amanda_part']['client']['dumpusergroup']
  mode 0755
  recursive true
  action :create
  not_if { File.exist?(node['amanda_part']['client']['script_dir']) }
end

currenthost_backup_restore_config = host_backup_restore_config.select do |hostname, config|
  puts hostname
  puts `hostname`.strip
  hostname if `hostname`.strip == hostname
end
currenthost_backup_restore_config.each do |hostname, config|
  data = config[:paths].select do |path_config|
    path_config unless path_config[:script].nil?
  end
  data.each do |path_config|
    script_path = File.join(node['amanda_part']['client']['script_dir'], "pre_backup_#{path_config[:postfix]}")
    template script_path do
      owner node['amanda_part']['client']['dumpuser']
      group node['amanda_part']['client']['dumpusergroup']
      source 'script.erb'
      mode 0755
      variables(
        script: path_config[:script][:backup]
      )
      not_if { path_config[:script][:backup].nil? }
    end
    script_path = File.join(node['amanda_part']['client']['script_dir'], "post_restore_#{path_config[:postfix]}")
    template script_path do
      owner node['amanda_part']['client']['dumpuser']
      group node['amanda_part']['client']['dumpusergroup']
      source 'script.erb'
      mode 0755
      variables(
        script: path_config[:script][:restore]
      )
      not_if { path_config[:script][:restore].nil? }
    end  
  end
end
