require_relative '../spec_helper'

describe 'amanda_part::all_configure_server' do
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

  it 'create .amandahosts' do
    expect(chef_run).to create_template('/var/lib/amanda/.amandahosts')
    file = chef_run.template('/var/lib/amanda/.amandahosts')
    expect(file.mode).to eq(0600)
  end

  describe 'roles configuration part' do
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
              'pre_backup_web_test' => {
                timing: 'pre-dle-backup',
                script: 'exit 0'
              },
              'post_restore_web_test' => {
                timing: 'pre-dle-backup',
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
      allow_any_instance_of(Chef::Recipe).to receive(:hosts_paths_privileges_under_role).and_return(test_parameter)
      allow_any_instance_of(Chef::Recipe).to receive(:amanda_config).and_return(test_config)
    end

    it 'create amanda directory' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/lib/amanda').and_return(false)
      expect(chef_run).to create_directory('/var/lib/amanda')
    end

    it 'create amanda config directory' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/etc/amanda').and_return(false)
      expect(chef_run).to create_directory('/etc/amanda')
    end

    it 'create amanda path config dir' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/etc/amanda/web_test').and_return(false)
      expect(chef_run).to create_directory('/etc/amanda/web_test')
    end

    it 'create amanda path vtapes directory' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test').and_return(false)
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test')
    end

    it 'create amanda path holding disk directory' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/lib/amanda/holding/web_test').and_return(false)
      expect(chef_run).to create_directory('/var/lib/amanda/holding/web_test')
    end

    it 'create amanda path curinfo directory' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/lib/amanda/state/curinfo/web_test').and_return(false)
      expect(chef_run).to create_directory('/var/lib/amanda/state/curinfo/web_test')
    end

    it 'create amanda path log directory' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/lib/amanda/log/web_test').and_return(false)
      expect(chef_run).to create_directory('/var/lib/amanda/log/web_test')
    end

    it 'create amanda path index directory' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/lib/amanda/index/web_test').and_return(false)
      expect(chef_run).to create_directory('/var/lib/amanda/index/web_test')
    end

    it 'create amanda path slot directories' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test/1').and_return(false)
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test/2').and_return(false)
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test/3').and_return(false)
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test/4').and_return(false)
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test/5').and_return(false)
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test/6').and_return(false)
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test/7').and_return(false)
      allow(File).to receive(:exist?).with('/var/lib/amanda/vtapes/web_test/8').and_return(false)
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test/1')
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test/2')
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test/3')
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test/4')
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test/5')
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test/6')
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test/7')
      expect(chef_run).to create_directory('/var/lib/amanda/vtapes/web_test/8')
    end

    it 'create disklist' do
      expect(chef_run).to create_template('/etc/amanda/web_test/disklist')
      file = chef_run.template('/etc/amanda/web_test/disklist')
      expect(file.mode).to eq(0644)
    end

    it 'create amanda.conf' do
      expect(chef_run).to create_template('/etc/amanda/web_test/amanda.conf')
      file = chef_run.template('/etc/amanda/web_test/amanda.conf')
      expect(file.mode).to eq(0644)
    end

    it 'create cron configuration file' do
      expect(chef_run).to create_template('/etc/cron.d/web_test')
      file = chef_run.template('/etc/cron.d/web_test')
      expect(file.mode).to eq(0644)
    end
  end
end
