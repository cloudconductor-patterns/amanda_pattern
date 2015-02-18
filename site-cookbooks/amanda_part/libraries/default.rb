# -*- coding: utf-8 -*-
# Copyright 2014 TIS Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/recipe'
require 'chef/resource'
require 'chef/provider'

require 'cloud_conductor_utils/consul'

module CloudConductor
  module AmandaPartHelper
    def role_backup_restore_config
      parameters = CloudConductorUtils::Consul.read_parameters
      parameters[:cloudconductor][:patterns].map do |_pattern_name, pattern|
        pattern[:config].nil? or pattern[:config][:backup].nil? ? nil : pattern[:config][:backup]
      end.compact.inject({}) do |result, config_backup_restore|
        ::Chef::Mixin::DeepMerge.deep_merge!(config_backup_restore, result)
      end
    end

    def host_backup_restore_config
      CloudConductorUtils::Consul.read_servers.inject({}) do |hosts_config, (hostname, server)|
        host_config = role_backup_restore_config.inject([]) do |host_role_config, (role, paths_config)|
          next host_role_config unless server[:roles].include?(role.to_s)
          host_role_paths_config = paths_config.map do |path_config|
            next if path_config[:path].nil?
            postfix = "#{hostname}#{path_config[:path].gsub('/', '_')}"
            schedule = path_config[:schedule]
            scripts = path_config[:script].nil? ? {} : path_config[:script].inject({}) do |script_config, (script_name, script)|
              script_config.merge!({
                "#{script_name}_#{postfix}" => {
                  timing: script_timing[script_name],
                  script: script
                }
              })
            end
            dumptype = "dumptype_#{postfix}"
            {
              path: path_config[:path],
              schedule: schedule.nil? ? node['amanda_part']['server']['schedule'] : schedule,
              scripts: scripts,
              dumptype: dumptype
            }
          end.compact
          host_role_config.concat(host_role_paths_config)
        end
        hosts_config.merge!(hostname => host_config)
      end
    end

    def script_timing
      {
        pre_backup: 'pre-dle-backup',
        post_backup: 'post-dle-backup',
        pre_restore: 'pre-recover',
        post_restore: 'post-recover'
      }
    end

    def amanda_config(hostname, path)
      storage = node['amanda_part']['server']['storage']
      config_name = "#{hostname}#{path.gsub('/', '_')}"
      {
        'name' => config_name,
        'config_dir' => File.join(node['amanda_part']['amanda_config_dir'], config_name),
        'vtapes_dir' => File.join(node['amanda_part']['server']['vtapes_dir'], config_name),
        'holding_dir' => File.join(node['amanda_part']['server']['holding_dir'], config_name),
        'state_dir' => File.join(node['amanda_part']['server']['state_dir'], config_name),
        'info_dir' => File.join(node['amanda_part']['server']['info_dir'], config_name),
        'log_dir' => File.join(node['amanda_part']['server']['log_dir'], config_name),
        'index_dir' => File.join(node['amanda_part']['server']['index_dir'], config_name),
        'slot' => node['amanda_part']['server']['slot'],
        'tapetype' => node['amanda_part']['server'][storage]['tapetype']['name'],
        'tpchanger' => node['amanda_part']['server'][storage]['tpchanger']['name'],
        'definition' => node['amanda_part']['server'][storage]['definition'],
        'autolabel' => node['amanda_part']['server'][storage]['autolabel'],
        'labelstr' => node['amanda_part']['server'][storage]['labelstr'],
        'dumpcycle' => node['amanda_part']['server']['dumpcycle'],
        'runspercycle' => node['amanda_part']['server']['runspercycle'],
        'tapecycle' => node['amanda_part']['server']['tapecycle'],
        'dumptype' => node['amanda_part']['server']['dumptype'],
        'holding_name' => "#{node['amanda_part']['server']['holding_prefix']}#{config_name}",
        'holding_use' => node['amanda_part']['server']['holding_use'],
        'holding_chunksize' => node['amanda_part']['server']['holding_chunksize'],
        'slot_dirs' => (1..node['amanda_part']['server']['slot']).to_a.map do |slot|
          File.join(File.join(node['amanda_part']['server']['vtapes_dir'], config_name), slot.to_s)
        end
      }
    end

    def server?
      hostname = `hostname`.strip
      server = server_info('backup').first
      server[:hostname] == hostname
    end
  end
end

Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)
Chef::Resource.send(:include, CloudConductor::AmandaPartHelper)
