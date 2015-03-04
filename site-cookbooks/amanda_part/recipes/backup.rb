role_host_config.each do |role, role_host_backup_restore_config|
  role_host_backup_restore_config[:paths].each do |path_config| 
    config = amanda_config(role, path_config[:path])
    execute "amdump_#{config[:name]}" do
      command "su - #{node['amanda_part']['user']} -c \"amdump #{config[:name]}\""
      only_if { amanda_server? }
    end
  end
end
