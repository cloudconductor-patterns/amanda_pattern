directory node['amanda_part']['client']['script_dir'] do
  owner node['amanda_part']['user']
  group node['amanda_part']['group']
  mode 0755
  recursive true
  action :create
  not_if { File.exist?(node['amanda_part']['client']['script_dir']) }
end

host_config.each do |role, role_config|
  role_config[:paths].each do |path_config|
    config = amanda_config(role, path_config[:path])
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
      hostname: current_hostname,
      privileges_config: role_config[:privileges]
    )
  end
end

ruby_block 'backup_restore_backup_ready_event' do
  block do
    `consul event -name="backup_ready" "${CONSUL_SECRET_KEY}"`
  end
end
