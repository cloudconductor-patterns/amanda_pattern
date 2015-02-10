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
  end
end

Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)
Chef::Resource.send(:include, CloudConductor::AmandaPartHelper)
