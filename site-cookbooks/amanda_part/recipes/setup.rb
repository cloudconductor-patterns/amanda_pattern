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

slot_dirs = (1..node['amanda_part']['server']['slot']).to_a.map do |slot|
  File.join(node['amanda_part']['server']['vtapes_dir'], slot.to_s)
end.join(',')
dirs = [
  node['amanda_part']['server']['amanda_dir'],
  node['amanda_part']['server']['amanda_config_dir'],
  node['amanda_part']['server']['vtapes_dir'],
  node['amanda_part']['server']['holding_dir'],
  node['amanda_part']['server']['info_file'],
  node['amanda_part']['server']['log_dir'],
  node['amanda_part']['server']['index_dir'],
  node['amanda_part']['server']['config_dir'],
  *slot_dirs
]
dirs.each do |dir|
  directory dir do
    owner node['amanda_part']['fileuser']
    group node['amanda_part']['fileusergroup']
    mode 0755
    recursive true
    action :create
    not_if { File.exist?(dir) }
  end
end

amanda_conf = File.join(node['amanda_part']['server']['config_dir'], 'amanda.conf')
template amanda_conf do
  owner node['amanda_part']['fileuser']
  group node['amanda_part']['fileusergroup']
  source 'amanda.conf.erb'
  mode 0644
  variables(dumptype_definitions: [])
end

