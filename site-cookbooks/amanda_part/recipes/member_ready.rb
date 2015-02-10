# update .amandahosts
server = server_info('backup').first
clients = CloudConductorUtils::Consul.read_servers

amandahosts = File.join(node['amanda_part']['server']['var_amanda_dir'], '.amandahosts')
template amandahosts do
  owner node['amanda_part']['server']['dumpuser']
  group node['amanda_part']['server']['dumpusergroup']
  source '.amandahosts-server.erb'
  mode 0644
  variables(
    server: server,
    clients: clients
  )
end

# update disklist
puts host_backup_restore_config

# update amanda.conf
