host_backup_restore_config.each do |hostname, backup_restore_config|
  backup_restore_config.each do |path_config|
    config = amanda_config(hostname, path_config[:path])
    execute "amdump_#{config['name']}" do
      command "su - #{node['amanda_part']['execuser']} -c \"amdump #{config['name']}\""
      only_if { server? }
    end
  end
end
