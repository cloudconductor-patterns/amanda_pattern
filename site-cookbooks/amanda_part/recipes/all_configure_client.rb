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
