Chef::Recipe.send(:include, CloudConductor::CommonHelper)
Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)

require 'aws-sdk-core'

parameters = CloudConductorUtils::Consul.read_parameters[:cloudconductor]
roles = ENV['ROLE'].split(',')
hosts_paths_privileges_by_role(roles, parameters).each do |role, role_config|
  role_config[:paths].each do |path_config|
    config = amanda_config(role, path_config[:path])
    restore_file = File.join(node['amanda_part']['amanda_restore_work_dir'], 'restore.tar')
    next unless path_config[:restore_enabled]
    execute 'execute pre_restore script' do
      command "su - #{node['amanda_part']['user']} -l -c /usr/libexec/amanda/application/pre_restore_#{config[:name]}"
      action :run
      not_if { path_config[:scripts]["pre_restore_#{config[:name]}"].nil? }
    end
    ruby_block 'download restore file' do
      block do
        bucket_name = node['amanda_part']['server']['s3']['tpchanger']['bucket_name']
        s3 = Aws::S3::Client.new(
          region: node['amanda_part']['server']['s3']['tpchanger']['s3_bucket_location'],
          access_key_id: node['amanda_part']['server']['s3']['tpchanger']['s3_access_key'],
          secret_access_key: node['amanda_part']['server']['s3']['tpchanger']['s3_secret_key']
        )
        objects = s3.list_objects(bucket: bucket_name)
        target_objects = objects.contents.select do |object|
          object.key.start_with?("#{role}/#{config[:disk_postfix]}/")
        end
        latest_object = target_objects.max do |left, right|
          left.last_modified <=> right.last_modified
        end
        File.open(restore_file, 'w') do |file|
          s3.get_object(bucket: bucket_name, key: latest_object.key) do |chunk|
            file.write(chunk)
          end
        end
      end
    end
    execute 'execute restore' do
      command "dd if=#{restore_file} bs=32k count=1 | tar -xpGC #{path_config[:path]}"
      action :run
    end
    execute 'execute post_restore script' do
      command "su - #{node['amanda_part']['user']} -l -c /usr/libexec/amanda/application/post_restore_#{config[:name]}"
      action :run
      not_if { path_config[:scripts]["post_restore_#{config[:name]}"].nil? }
    end
  end
end
