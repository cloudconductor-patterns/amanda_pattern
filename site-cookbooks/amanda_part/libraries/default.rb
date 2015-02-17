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
    def backup_restore_roles
      parameters = CloudConductorUtils::Consul.read_parameters
      patterns = parameters[:cloudconductor][:patterns]
      roles = []
      patterns.each do |_, pattern|
        next if pattern[:config].nil? or pattern[:config][:backup].nil?
        pattern[:config][:backup].each do |role, _pattern_config|
          roles << role
        end
      end
      roles.uniq
    end
    def host_backup_restore_config
      config = {}
      all_servers = CloudConductorUtils::Consul.read_servers
      servers = all_servers.each do |hostname, server|
        host_role_config = role_backup_restore_config.select do |role|
          role if server[:roles].include?(role.to_s)
        end
        temp_config = {}
        host_role_config.each do |role, role_config|
          ::Chef::Mixin::DeepMerge.deep_merge!(role_config, temp_config)
        end
        next if temp_config[:paths].nil?
        config[hostname] = temp_config
        config[hostname][:paths].map! do |path_config|
          path = path_config[:path].gsub('/', '_')
          postfix = path_config[:script].nil? ? node['amanda_part']['server']['dumptype'] : "#{hostname}#{path}"
          path_config[:postfix] = postfix
          path_config
        end
      end
      config
    end

    def role_backup_restore_config
      parameters = CloudConductorUtils::Consul.read_parameters
      patterns = parameters[:cloudconductor][:patterns]
      config = {}
      patterns.each do |_, pattern|
        next if pattern[:config].nil? or pattern[:config][:backup].nil?
        pattern[:config][:backup].each do |role, pattern_config|
          config[role] = {} if config[role].nil?
          ::Chef::Mixin::DeepMerge.deep_merge!(pattern_config, config[role])
        end
      end
      config
    end

    def amanda_config(config_name)
      config = {}
      config['name'] = config_name
      config['config_dir'] = File.join(node['amanda_part']['amanda_config_dir'], config_name)
      config['vtapes_dir'] = File.join(node['amanda_part']['server']['vtapes_dir'], config_name)
      config['holding_dir'] = File.join(node['amanda_part']['server']['holding_dir'], config_name)
      config['state_dir'] = File.join(node['amanda_part']['server']['state_dir'], config_name)
      config['info_dir'] = File.join(node['amanda_part']['server']['info_dir'], config_name)
      config['log_dir'] = File.join(node['amanda_part']['server']['log_dir'], config_name)
      config['index_dir'] = File.join(node['amanda_part']['server']['index_dir'], config_name)
      config['slot'] = node['amanda_part']['server']['slot']
      storage = node['amanda_part']['server']['storage']
      config['tapetype'] = node['amanda_part']['server'][storage]['tapetype']['name']
      config['tpchanger'] = node['amanda_part']['server'][storage]['tpchanger']['name']
      config['definition'] = node['amanda_part']['server'][storage]['definition']
      config['autolabel'] = node['amanda_part']['server'][storage]['autolabel']
      config['labelstr'] = node['amanda_part']['server'][storage]['labelstr']
      config['dumpcycle'] = node['amanda_part']['server']['dumpcycle']
      config['runspercycle'] = node['amanda_part']['server']['runspercycle']
      config['tapecycle'] = node['amanda_part']['server']['tapecycle']
      config['dumptype'] = node['amanda_part']['server']['dumptype']
      config['holding_name'] = "#{node['amanda_part']['server']['holding_prefix']}#{config_name}"
      config['holding_use'] = node['amanda_part']['server']['holding_use']
      config['holding_chunksize'] = node['amanda_part']['server']['holding_chunksize']
      config['slot_dirs'] = (1..config['slot']).to_a.map do |slot|
        File.join(config['vtapes_dir'], slot.to_s)
      end
      config
    end

    def all_paths
      parameters = CloudConductorUtils::Consul.read_parameters
      patterns = parameters[:cloudconductor][:patterns]
      paths = []
      patterns.each do |_pattern_name, pattern|
        next if pattern[:config].nil? or pattern[:config][:backup].nil?
        pattern[:config][:backup].each do |_role, backup_config|
          next if backup_config[:paths].nil?
          backup_config[:paths].each do |path_config|
            puts path_config
            paths << path_config[:path]
          end
        end
      end
      paths.uniq
    end
  end
end

Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)
Chef::Resource.send(:include, CloudConductor::AmandaPartHelper)
