require_relative '../spec_helper'

describe 'amanda_part::restore_s3' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  test_parameter = {
    web: {
      hosts: {
        'testhost' =>
        {
          roles: ['web'],
          pattern: 'test_pattern',
          private_ip: '127.0.0.1'
        }
      },
      paths: [
        {
          path: '/test',
          schedule: '0 0 * * *',
          restore_enabled: true,
          prepare_path: true,
          scripts: {
            'pre_restore_web_test' => {
              timing: 'pre-recover',
              script: 'exit 0'
            },
            'post_restore_web_test' => {
              timing: 'post-recover',
              script: 'exit 0'
            }
          },
          dumptype: 'dumptype_web_test'
        }
      ],
      privileges: [
        {
          user: 'root',
          command: 'ls'
        }
      ]
    }
  }
  test_config = {
    name: 'web_test',
    role: :db,
    disk_postfix: '_test',
    config_dir: '/etc/amanda/web_test',
    vtapes_dir: '/var/lib/amanda/vtapes/web_test',
    holding_dir: '/var/lib/amanda/holding/web_test',
    state_dir: '/var/lib/amanda/state/web_test',
    info_dir: '/var/lib/amanda/state/curinfo/web_test',
    log_dir: '/var/lib/amanda/log/web_test',
    index_dir: '/var/lib/amanda/index/web_test',
    slot: 8,
    tapetype: 'S3',
    tpchanger: 's3_tpchanger',
    definition: nil,
    autolabel: 'S3-%%%%',
    labelstr: '^S3-[0-9][0-9]*$',
    dumpcycle: '1 weeks',
    runspercycle: '7 days',
    tapecycle: '8 tapes',
    dumptype: 'dumptype_tar',
    holding_name: 'hd_web_test',
    holding_use: '100 mbytes',
    holding_chunksize: '1 mbyte',
    slot_dirs: [
      '/var/lib/amanda/vtapes/web_test/1',
      '/var/lib/amanda/vtapes/web_test/2',
      '/var/lib/amanda/vtapes/web_test/3',
      '/var/lib/amanda/vtapes/web_test/4',
      '/var/lib/amanda/vtapes/web_test/5',
      '/var/lib/amanda/vtapes/web_test/6',
      '/var/lib/amanda/vtapes/web_test/7',
      '/var/lib/amanda/vtapes/web_test/8'
    ],
    storage: 's3'
  }

  before do
    ENV['ROLE'] = 'web'
    require 'aws-sdk-core'
    s3_list_objects_contents = [
      double(
        'object1',
        key: 'web/slot-0000-filestart',
        last_modified: '2015/01/01'
      )
    ]
    s3_list_objects = double('s3_list_objects', contents: s3_list_objects_contents)
    s3 = double('s3', list_objects: s3_list_objects)
    allow(Aws::S3::Client).to receive(:new).and_call_original
    allow(Aws::S3::Client).to receive(:new).and_return(s3)
    allow_any_instance_of(Chef::Recipe).to receive(:hosts_paths_privileges_by_role).and_return(test_parameter)
    allow_any_instance_of(Chef::Recipe).to receive(:amanda_config).and_return(test_config)
  end

  it 'delete restore work directory' do
    allow(File).to receive(:exist?).and_return(true)
    expect(chef_run).to delete_directory('/var/lib/amanda/restore')
  end

  it 'recreate restore work directory' do
    allow(File).to receive(:exist?).and_return(false)
    expect(chef_run).to create_directory('/var/lib/amanda/restore')
  end

  it 'execute pre_restore script' do
    expect(chef_run).to run_execute('execute pre_restore script')
  end

  it 'download restore file' do
    expect(chef_run).to run_ruby_block('download restore file')
  end

  it 'concatenate restore files' do
    expect(chef_run).to run_execute('concatenate restore files')
  end

  it 'cleanup target directory' do
    expect(chef_run).to run_ruby_block('cleanup target directory')
  end

  it 'execute restore' do
    expect(chef_run).to run_execute('execute restore')
  end

  it 'execute post_restore script' do
    expect(chef_run).to run_execute('execute post_restore script')
  end
end
