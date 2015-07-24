Chef::Recipe.send(:include, CloudConductor::CommonHelper)
Chef::Recipe.send(:include, CloudConductor::AmandaPartHelper)

gem_package 'aws-sdk-core' do
  action :install
end

directory node['amanda_part']['client']['script_dir'] do
  owner node['amanda_part']['user']
  group node['amanda_part']['group']
  mode 0755
  recursive true
  action :create
  not_if { File.exist?(node['amanda_part']['client']['script_dir']) }
end

include_recipe 'amanda_part::all_configure_client'
include_recipe 'amanda_part::all_configure_server' if amanda_server?
