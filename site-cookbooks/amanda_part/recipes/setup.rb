remote_file "#{Chef::Config[:file_cache_path]}/amanda-backup_server-3.3.6-1.rhel6.x86_64.rpm" do
  source 'http://www.zmanda.com/downloads/community/Amanda/3.3.6/Redhat_Enterprise_6.0/amanda-backup_server-3.3.6-1.rhel6.x86_64.rpm'
  notifies :install, 'yum_package[amanda-backup_server]', :immediately
end

yum_package 'amanda-backup_server' do
  source "#{Chef::Config[:file_cache_path]}/amanda-backup_server-3.3.6-1.rhel6.x86_64.rpm"
  action :nothing
end

service 'xinetd' do
  supports status: true, restart: true, reload: true
  action :nothing
end

proxies = {
  'http_proxy' => ENV['http_proxy'],
  'https_proxy' => ENV['https_proxy'],
  'no_proxy' => ENV['no_proxy']
}
env_parameter = proxies.each_with_object([]) do |(key, value), result|
  result << "#{key}=#{value}" if not value.nil?
end
env_parameter.unshift('env             =') if not env_parameter.empty?

template '/etc/xinetd.d/amandaserver' do
  owner node['amanda_part']['user']
  group node['amanda_part']['group']
  source 'amandaserver.erb'
  mode 0644
  variables(
    env_parameter: env_parameter.join(' ')
  )
  notifies :restart, 'service[xinetd]', :immediate
end

service 'consul' do
  supports status: true, restart: true, reload: true
  action :nothing
end

template '/etc/consul.d/watches_backup_restore.json' do
  source 'watches_backup_restore.json.erb'
  mode 0644
  notifies :reload, 'service[consul]', :immediate
end
