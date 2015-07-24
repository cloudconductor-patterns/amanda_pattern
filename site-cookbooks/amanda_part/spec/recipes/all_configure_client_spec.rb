require_relative '../spec_helper'

describe 'amanda_part::all_configure_client' do
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

  it 'download amanda-backup_client package' do
    expect(chef_run).to create_remote_file(/.*amanda-backup_client-3\.3\.6-1\.rhel6\.x86_64\.rpm/).with(
      source: 'http://www.zmanda.com/downloads/community/Amanda/3.3.6/Redhat_Enterprise_6.0/amanda-backup_client-3.3.6-1.rhel6.x86_64.rpm'
    )
    file = chef_run.remote_file(/.*amanda-backup_client-3\.3\.6-1\.rhel6\.x86_64\.rpm/)
    expect(file).to notify('yum_package[amanda-backup_client]').to(:install)
  end

  it 'install amandaclient service file' do
    expect(chef_run).to create_cookbook_file('/etc/xinetd.d/amandaclient')
    file = chef_run.cookbook_file('/etc/xinetd.d/amandaclient')
    expect(file.mode).to eq(0644)
    expect(file).to notify('service[xinetd]').to(:restart)
  end

  it 'create amanda data directory' do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/var/lib/amanda').and_return(false)
    expect(chef_run).to create_directory('/var/lib/amanda')
  end

  it 'create .amandahosts' do
    expect(chef_run).to create_template('/var/lib/amanda/.amandahosts')
    file = chef_run.template('/var/lib/amanda/.amandahosts')
    expect(file.mode).to eq(0600)
  end
end
