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
    def host_config
      CloudConductorUtils::Consul.read_servers.inject({}) do |host_config, (hostname, server_info)|
        host_config.merge(hostname => host_role_config(hostname, server_info))
      end
    end

    def host_role_config(hostname, server_info)
      role_config.inject([]) do |host_role_config, (role, paths_parameter)|
        next host_role_config unless server_info[:roles].include?(role.to_s)
        paths_config = paths_parameter.map do |path_parameter|
          path_parameter[:path].nil? ? nil : path_config(hostname, path_parameter)
        end.compact
        host_role_config.concat(paths_config)
      end
    end

    def role_config
      patterns = CloudConductorUtils::Consul.read_parameters[:cloudconductor][:patterns]
      patterns.inject({}) do |role_config, (_pattern_name, pattern)|
        next role_config if pattern[:config].nil? || pattern[:config][:backup_restore].nil?
        ::Chef::Mixin::DeepMerge.deep_merge!(pattern[:config][:backup_restore], role_config)
      end
    end

    def path_config(hostname, path_parameter)
      postfix = "#{hostname}#{path_parameter[:path].gsub('/', '_')}"
      schedule = path_parameter[:schedule]
      scripts = path_parameter[:script].nil? ? {} : path_parameter[:script].inject({}) do |script_config, (script_name, script)|
        script_config.merge(
          "#{script_name}_#{postfix}" => {
            timing: script_timing[script_name],
            script: script
          }
        )
      end
      dumptype = "dumptype_#{postfix}"
      {
        path: path_parameter[:path],
        schedule: schedule.nil? ? node['amanda_part']['server']['schedule'] : schedule,
        scripts: scripts,
        dumptype: dumptype
      }
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
      disk_postfix = path.gsub('/', '_')
      config_name = "#{hostname}#{disk_postfix}"
      {
        name: config_name,
        hostname: hostname,
        disk_postfix: disk_postfix,
        config_dir: File.join(node['amanda_part']['amanda_config_dir'], config_name),
        vtapes_dir: File.join(node['amanda_part']['server']['vtapes_dir'], config_name),
        holding_dir: File.join(node['amanda_part']['server']['holding_dir'], config_name),
        state_dir: File.join(node['amanda_part']['server']['state_dir'], config_name),
        info_dir: File.join(node['amanda_part']['server']['info_dir'], config_name),
        log_dir: File.join(node['amanda_part']['server']['log_dir'], config_name),
        index_dir: File.join(node['amanda_part']['server']['index_dir'], config_name),
        slot: node['amanda_part']['server']['slot'],
        tapetype: node['amanda_part']['server'][storage]['tapetype']['name'],
        tpchanger: node['amanda_part']['server'][storage]['tpchanger']['name'],
        definition: node['amanda_part']['server'][storage]['definition'],
        autolabel: node['amanda_part']['server'][storage]['autolabel'],
        labelstr: node['amanda_part']['server'][storage]['labelstr'],
        dumpcycle: node['amanda_part']['server']['dumpcycle'],
        runspercycle: node['amanda_part']['server']['runspercycle'],
        tapecycle: node['amanda_part']['server']['tapecycle'],
        dumptype: node['amanda_part']['server']['dumptype'],
        holding_name: "#{node['amanda_part']['server']['holding_prefix']}#{config_name}",
        holding_use: node['amanda_part']['server']['holding_use'],
        holding_chunksize: node['amanda_part']['server']['holding_chunksize'],
        slot_dirs: (1..node['amanda_part']['server']['slot']).to_a.map do |slot|
          File.join(File.join(node['amanda_part']['server']['vtapes_dir'], config_name), slot.to_s)
        end,
        storage: node['amanda_part']['server']['storage']
      }
    end

    def hostname
      `hostname`.strip
    end

    def amanda_server_name
      server_info('backup_restore').first[:hostname]
    end

    def server?
      amanda_server_name == hostname
    end
  end
end

Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)
Chef::Resource.send(:include, CloudConductor::AmandaPartHelper)
