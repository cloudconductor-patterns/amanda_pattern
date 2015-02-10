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
end
