hostname = `hostname`.strip
host_backup_restore_config[hostname].each do |path_config|
  config = amanda_config(hostname, path_config[:path])
  bash "amrecover_#{config['name']}" do
  code <<-EOH
    amrecover -C #{config['name']} <<EOF
      setdisk #{path_config[:path]}
      lcd #{path_config[:path]}
      add *
      extract
      Y
      Y
      exit
    EOF
  EOH
  end
end
