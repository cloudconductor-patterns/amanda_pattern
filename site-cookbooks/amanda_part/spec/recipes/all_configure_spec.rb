require_relative '../spec_helper'

describe 'amanda_part::all_configure' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

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

  it 'issue backup_ready event' do
    expect(chef_run).to run_ruby_block('backup_restore_backup_ready_event')
  end
end
