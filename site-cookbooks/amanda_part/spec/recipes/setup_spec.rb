require_relative '../spec_helper'

describe 'amanda_part::setup' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'download amanda-backup_server package' do
    expect(chef_run).to create_remote_file(/.*amanda-backup_server-3\.3\.6-1\.rhel6\.x86_64\.rpm/).with(
      source: 'http://www.zmanda.com/downloads/community/Amanda/3.3.6/Redhat_Enterprise_6.0/amanda-backup_server-3.3.6-1.rhel6.x86_64.rpm'
    )
  end

  it 'install amandaserver service file' do
    expect(chef_run).to create_template('/etc/xinetd.d/amandaserver')
  end

  it 'install watches for backup_restore'  do
    expect(chef_run).to create_template('/etc/consul.d/watches_backup_restore.json')
  end
end
