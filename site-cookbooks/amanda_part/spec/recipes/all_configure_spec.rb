require_relative '../spec_helper'

describe 'amanda_part::all_configure' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  before do
    server_info = {
      hostname: 'testhost',
      roles: ['backup_restore'],
      pattern: 'amanda_pattern',
      private_ip: '127.0.0.1'
    }
    allow_any_instance_of(Chef::Recipe).to receive(:amanda_server).and_return(server_info)
    allow_any_instance_of(Chef::Resource).to receive(:amanda_server).and_return(server_info)
  end

  it 'install aws-sdk-core gem package' do
    expect(chef_run).to install_gem_package('aws-sdk-core')
  end

  it 'create script directory' do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/usr/libexec/amanda/application').and_return(false)
    expect(chef_run).to create_directory('/usr/libexec/amanda/application')
  end

  it 'include all_configure_server' do
    allow_any_instance_of(Chef::Recipe).to receive(:amanda_server?).and_return(true)
    expect(chef_run).to include_recipe 'amanda_part::all_configure_server'
  end

  it 'include all_configure_client' do
    allow_any_instance_of(Chef::Recipe).to receive(:amanda_server?).and_return(false)
    expect(chef_run).to include_recipe 'amanda_part::all_configure_client'
  end
end
