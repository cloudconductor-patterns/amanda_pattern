Chef::Recipe.send(:include, CloudConductor::CommonHelper)
Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)

require 'aws-sdk-core'

bucket_name = node['amanda_part']['server']['s3']['tpchanger']['bucket_name']
s3 = Aws::S3::Client.new(
  region: node['amanda_part']['server']['s3']['tpchanger']['s3_bucket_location'],
  access_key_id: node['amanda_part']['server']['s3']['tpchanger']['s3_access_key'],
  secret_access_key: node['amanda_part']['server']['s3']['tpchanger']['s3_secret_key']
)

target_bucket = s3.list_buckets.buckets.select do |bucket|
  bucket.name == bucket_name
end

parameters = CloudConductorUtils::Consul.read_parameters[:cloudconductor]
roles = ENV['ROLE'].split(',')

unless target_bucket.size == 0
  hosts_paths_privileges_by_role(roles, parameters).each do |role, role_config|
    role_config[:paths].each do |path_config|
      config = amanda_config(role, path_config[:path])
      restore_file = File.join(node['amanda_part']['amanda_restore_work_dir'], 'restore.tar')
      next unless path_config[:restore_enabled] && s3.list_objects(bucket: bucket_name).contents.size > 0
      directory node['amanda_part']['amanda_restore_work_dir'] do
        recursive true
        action :delete
        only_if { File.exist?(node['amanda_part']['amanda_restore_work_dir']) }
      end
      directory node['amanda_part']['amanda_restore_work_dir'] do
        mode 0755
        recursive true
        action :create
        not_if { File.exist?(node['amanda_part']['amanda_restore_work_dir']) }
      end
      execute 'execute pre_restore script' do
        command "su - #{node['amanda_part']['user']} -l -c /usr/libexec/amanda/application/pre_restore_#{config[:name]}"
        action :run
        not_if { path_config[:scripts]["pre_restore_#{config[:name]}"].nil? }
      end
      ruby_block 'download restore file' do
        block do
          path_pattern = "#{role}/#{config[:disk_postfix]}/"
          filestart_pattern = "#{path_pattern}.*-filestart"
          data_pattern = "#{path_pattern}.*\.data"
          objects = s3.list_objects(bucket: bucket_name)
          target_filestarts = objects.contents.select do |object|
            object.key.match(/#{filestart_pattern}/)
          end
          exists_filestarts = target_filestarts.each_with_object([]) do |object, result|
            s3.get_object(bucket: bucket_name, key: object.key) do |chunk|
              result << object if chunk.match(/^ORIGSIZE=10$/m).nil?
            end
          end
          if exists_filestarts.empty?
            latest_filestart = target_filestarts.sort! do |left, right|
              left.last_modified <=> right.last_modified
            end.last
          else
            latest_filestart = exists_filestarts.sort! do |left, right|
              left.last_modified <=> right.last_modified
            end.last
          end
          filestart_elements = latest_filestart.key.match(/(#{path_pattern})(.*)-(.*)-filestart/)
          data_pattern = "#{path_pattern}#{filestart_elements[2]}-#{filestart_elements[3]}-.*\.data"
          target_objects = objects.contents.select do |object|
            object.key.match(/#{data_pattern}/)
          end
          latest_object = target_objects.max do |left, right|
            left.last_modified <=> right.last_modified
          end
          latest_data = latest_object.key.match(/(#{path_pattern})(.*)-(.*)-(.*)\.data/)
          latest_data_prefix = "#{latest_data[1]}#{latest_data[2]}-#{latest_data[3]}-"
          restore_objects = target_objects.select do |object|
            object.key.match(/#{latest_data_prefix}/)
          end
          restore_objects.each do |object|
            File.open("#{node['amanda_part']['amanda_restore_work_dir']}/#{object.key.gsub('/', '_')}", 'w') do |file|
              s3.get_object(bucket: bucket_name, key: object.key) do |chunk|
                file.write(chunk)
              end
            end
          end
        end
      end
      execute 'concatenate restore files' do
        command "cat #{node['amanda_part']['amanda_restore_work_dir']}/*.data > #{restore_file}"
        action :run
      end
      ruby_block 'cleanup target directory' do
        block do
          require 'fileutils'
          FileUtils.rm_rf "#{path_config[:path]}/*"
        end
      end
      execute 'execute restore' do
        command "tar xvf #{restore_file}"
        cwd path_config[:path]
        action :run
      end
      execute 'execute post_restore script' do
        command "su - #{node['amanda_part']['user']} -l -c /usr/libexec/amanda/application/post_restore_#{config[:name]}"
        action :run
        not_if { path_config[:scripts]["post_restore_#{config[:name]}"].nil? }
      end
    end
  end
end
