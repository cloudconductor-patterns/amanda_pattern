require_relative '../spec_helper'

describe 'amanda_part::all_configure_server' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }
  
  test_parameter = {
    :web => {
      :hosts => {
        'testhost'=>
        {
          :roles=>['web'],
          :pattern=>'test_pattern',
          :private_ip=>'127.0.0.1'
        }
      },
      :paths => [
        {
          :path => '/test',
          :schedule => '0 0 * * *',
          :restore_enabled => true,
          :prepare_path => true,
          :scripts => {
            'pre_backup_web_test' => {
              :timing => 'pre-dle-backup',
              :script => 'exit 0'
            },
            'post_restore_web_test' => {
              :timing => 'pre-dle-backup',
              :script => 'exit 0'
            }
          },
          :dumptype => 'dumptype_web_test'
        }
      ],
      :privileges => [
        {
          :user => "root",
          :command => "ls"
        }
      ]
    }
  }
  test_config = {
    :name => 'web_test',
    :role => :db,
    :disk_postfix => '_test',
    :config_dir => '/etc/amanda/web_test',
    :vtapes_dir => '/var/lib/amanda/vtapes/web_test',
    :holding_dir => '/var/lib/amanda/holding/web_test',
    :state_dir => '/var/lib/amanda/state/web_test',
    :info_dir => '/var/lib/amanda/state/curinfo/web_test',
    :log_dir => '/var/lib/amanda/log/web_test',
    :index_dir => '/var/lib/amanda/index/web_test',
    :slot => 8,
    :tapetype => 'S3',
    :tpchanger => 's3_tpchanger',
    :definition => nil,
    :autolabel => 'S3-%%%%',
    :labelstr => '^S3-[0-9][0-9]*$',
    :dumpcycle => '1 weeks',
    :runspercycle => '7 days',
    :tapecycle => '8 tapes',
    :dumptype => 'dumptype_tar',
    :holding_name => 'hd_web_test',
    :holding_use => '100 mbytes',
    :holding_chunksize => '1 mbyte',
    :slot_dirs => [
      '/var/lib/amanda/vtapes/web_test/1',
      '/var/lib/amanda/vtapes/web_test/2',
      '/var/lib/amanda/vtapes/web_test/3',
      '/var/lib/amanda/vtapes/web_test/4',
      '/var/lib/amanda/vtapes/web_test/5',
      '/var/lib/amanda/vtapes/web_test/6',
      '/var/lib/amanda/vtapes/web_test/7',
      '/var/lib/amanda/vtapes/web_test/8'
    ],
    :storage => 's3'
  }

  before do
    allow_any_instance_of(Chef::Recipe).to receive(:hosts_paths_privileges_by_role).and_return(test_parameter)
    allow_any_instance_of(Chef::Recipe).to receive(:amanda_config).and_return(test_config)
  end
   
  it 'create pre backup script' do
    expect(chef_run).to create_template('/usr/libexec/amanda/application/pre_backup_web_test')
    file = chef_run.template('/usr/libexec/amanda/application/pre_backup_web_test')
    expect(file.mode).to eq(0755)
  end

  it 'create post restore script' do
    expect(chef_run).to create_template('/usr/libexec/amanda/application/post_restore_web_test')
    file = chef_run.template('/usr/libexec/amanda/application/post_restore_web_test')
    expect(file.mode).to eq(0755)
  end

  it 'create sudoers configuration file' do
    expect(chef_run).to create_template('/etc/sudoers.d/backup_restore_web')
    file = chef_run.template('/etc/sudoers.d/backup_restore_web')
    expect(file.mode).to eq(0600)
  end
end
