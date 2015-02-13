# update .amandahosts
server = server_info('backup').first
clients = CloudConductorUtils::Consul.read_servers

amandahosts = File.join(node['amanda_part']['server']['var_amanda_dir'], '.amandahosts')
template amandahosts do
  owner node['amanda_part']['server']['dumpuser']
  group node['amanda_part']['server']['dumpusergroup']
  source '.amandahosts-server.erb'
  mode 0600
  variables(
    server: server,
    clients: clients
  )
end

# update disklist
backup_restore_config = host_backup_restore_config
disklist = File.join(node['amanda_part']['server']['config_dir'], 'disklist')
template disklist do
  owner node['amanda_part']['server']['dumpuser']
  group node['amanda_part']['server']['dumpusergroup']
  source 'disklist.erb'
  mode 0644
  variables(
    backup_restore_config: backup_restore_config
  )
end

# update dumptype definitions in amanda.conf
definitions = []
host_backup_restore_config.each do |hostname, config|
  data = config[:paths].select do |path_config|
    path_config unless path_config[:script].nil?
  end
  data.each do |path_config|
    definition = <<DEFINITION
define script-tool pre_backup_#{path_config[:postfix]} {
  plugin "pre_backup_#{path_config[:postfix]}"
  execute-where client
  execute-on pre-dle-backup
}

define script-tool post_restore_#{path_config[:postfix]} {
  plugin  "post_restore_#{path_config[:postfix]}"
  execute-where client
  execute-on post-recover
}

define dumptype dumptype_#{path_config[:postfix]} {
  dumptype_#{node['amanda_part']['server']['dumptype']}
  script "pre_backup_#{path_config[:postfix]}"
  script "post_restore_#{path_config[:postfix]}"
}
DEFINITION
    definitions << definition
  end
end

amanda_conf = File.join(node['amanda_part']['server']['config_dir'], 'amanda.conf')
template amanda_conf do
  owner node['amanda_part']['server']['dumpuser']
  group node['amanda_part']['server']['dumpusergroup']
  source 'amanda.conf.erb'
  mode 0644
  variables(
    dumptype_definitions: definitions
  )
end
