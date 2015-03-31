require_relative '../spec_helper'

describe 'amanda_part::setup' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'download amanda-backup_server package' do
    expect(chef_run).to create_remote_file(/.*amanda-backup_server-3\.3\.6-1\.rhel6\.x86_64\.rpm/).with(
      source: 'http://www.zmanda.com/downloads/community/Amanda/3.3.6/Redhat_Enterprise_6.0/amanda-backup_server-3.3.6-1.rhel6.x86_64.rpm'
    )
    file = chef_run.remote_file(/.*amanda-backup_server-3\.3\.6-1\.rhel6\.x86_64\.rpm/)
    expect(file).to notify('yum_package[amanda-backup_server]').to(:install)
  end

  it 'install amandaserver service file' do
    expect(chef_run).to create_template('/etc/xinetd.d/amandaserver')
    file = chef_run.template('/etc/xinetd.d/amandaserver')
    expect(file.mode).to eq(0644)
    expect(file).to notify('service[xinetd]').to(:restart)
  end

  it 'install watches for backup_restore'  do
    expect(chef_run).to create_template('/etc/consul.d/watches_backup_restore.json')
    file = chef_run.template('/etc/consul.d/watches_backup_restore.json')
    expect(file.mode).to eq(0644)
    expect(file).to notify('service[consul]').to(:reload)
  end
end
