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

require 'socket'

module CloudConductor
  # rubocop: disable ModuleLength
  module AmandaPartHelper
    def hosts_paths_privileges_by_role(roles, parameters)
      return {} if roles.nil? || parameters.nil?
      roles_config = hosts_paths_privileges_under_role(parameters)
      roles_config.inject({}) do |result, (role, role_config)|
        next result unless roles.include?(role.to_s)
        ::Chef::Mixin::DeepMerge.deep_merge!(
          { role => role_config },
          result
        )
      end
    end

    # rubocop: disable MethodLength
    def hosts_paths_privileges_under_role(parameters)
      return {} if parameters.nil?
      patterns = parameters[:patterns] || {}
      role_config = patterns.inject({}) do |result, (_pattern_name, pattern)|
        next result if pattern[:config].nil? || pattern[:config][:backup_restore].nil?
        ::Chef::Mixin::DeepMerge.deep_merge!(pattern[:config][:backup_restore], result)
      end
      ::Chef::Mixin::DeepMerge.deep_merge!(
        application_hosts_paths_privileges_under_role(parameters),
        role_config
      )
      role_config.inject({}) do |result, (role, role_parameter)|
        ::Chef::Mixin::DeepMerge.deep_merge!(
          {
            role => {
              hosts: hosts_under_role(role),
              paths: paths_under_role(role, role_parameter[:paths]),
              privileges: role_parameter[:privileges] || []
            }
          },
          result
        )
      end
    end
    # rubocop: enable MethodLength

    def application_hosts_paths_privileges_under_role(parameters)
      applications = parameters[:applications] || {}
      applications.inject({}) do |result, (_application_name, application)|
        next result if application[:parameters].nil? || application[:parameters][:backup_restore].nil?
        ::Chef::Mixin::DeepMerge.deep_merge!(application[:parameters][:backup_restore], result)
      end
    end

    def hosts_under_role(role)
      if node['cloudconductor'] && node['cloudconductor']['servers']
        servers = node['cloudconductor']['servers']
      end
      return [] if servers.nil?
      servers.select do |_hostname, server_info|
        server_info['roles'].include?(role.to_s)
      end
    end

    def paths_under_role(role, paths_parameter)
      return [] if paths_parameter.nil?
      paths_parameter.map do |path_parameter|
        path_parameter[:path].nil? ? nil : path_under_paths(role, path_parameter)
      end.compact
    end

    def path_under_paths(role, path_parameter)
      return {} if path_parameter.nil?
      config_name = amanda_config_name(role, path_parameter[:path])
      dumptype = "dumptype_#{config_name}"
      {
        path: path_parameter[:path],
        schedule: path_parameter[:schedule] || node['amanda_part']['server']['schedule'],
        restore_enabled: path_parameter[:restore_enabled] || false,
        prepare_path: path_parameter[:prepare_path] || false,
        scripts: scripts_under_path(path_parameter, config_name),
        dumptype: dumptype
      }
    end

    def scripts_under_path(path_parameter, config_name)
      return {} if path_parameter[:script].nil?
      path_parameter[:script].inject({}) do |script_config, (script_name, script)|
        script_config.merge(
          "#{script_name}_#{config_name}" => {
            timing: script_timing[script_name.to_sym],
            script: script
          }
        )
      end
    end

    def script_timing
      {
        'pre_backup' => 'pre-dle-backup',
        'post_backup' => 'post-dle-backup',
        'pre_restore' => 'pre-recover',
        'post_restore' => 'post-recover'
      }
    end

    def amanda_config_name(role, path)
      "#{role}#{path.gsub(/\/|\./, '_')}"
    end

    # rubocop: disable MethodLength
    def amanda_config(role, path)
      storage = node['amanda_part']['server']['storage']
      disk_postfix = path.gsub(/\/|\./, '_')
      config_name = amanda_config_name(role, path)
      {
        name: config_name,
        role: role,
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
    # rubocop: enable MethodLength

    def amanda_server
      server = server_info('backup_restore').first
      private_ip = server['private_ip'].split('.').map(&:to_i).pack('C4')
      begin
        server[:alias] = Socket.gethostbyaddr(private_ip)[0]
      rescue SocketError
        server[:alias] = nil
      end
      server
    end

    def amanda_clients
      if node['cloudconductor'] && node['cloudconductor']['servers']
        servers = node['cloudconductor']['servers']
      else
        servers = {}
      end
      servers.each_with_object({}) do |(hostname, client), result|
        server = {}
        server[:hostname] = hostname
        server[:private_ip] = client[:private_ip]
        begin
          private_ip = client[:private_ip].split('.').map(&:to_i).pack('C4')
          server[:alias] = Socket.gethostbyaddr(private_ip)[0]
        rescue SocketError
          server[:alias] = nil
        end
        result[hostname] = server
      end
    end

    def amanda_server?
      amanda_server[:hostname] == node['hostname']
    end
  end
  # rubocop: enable ModuleLength
end
