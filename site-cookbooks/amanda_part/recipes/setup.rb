remote_file "#{Chef::Config[:file_cache_path]}/amanda-backup_server-3.3.6-1.rhel6.x86_64.rpm" do
  source 'http://www.zmanda.com/downloads/community/Amanda/3.3.6/Redhat_Enterprise_6.0/amanda-backup_server-3.3.6-1.rhel6.x86_64.rpm'
  notifies :install, "yum_package[amanda-backup_server]", :immediately
end

yum_package 'amanda-backup_server' do
  source "#{Chef::Config[:file_cache_path]}/amanda-backup_server-3.3.6-1.rhel6.x86_64.rpm"
  action :nothing
end

service 'xinetd' do
    supports status: true, restart: true, reload: true
    action :nothing
end

cookbook_file '/etc/xinetd.d/amandaserver' do
  owner node['amanda_part']['fileuser']
  group node['amanda_part']['fileusergroup']
  source 'amandaserver'
  mode 0644
  notifies :restart, 'service[xinetd]', :immediate
end
