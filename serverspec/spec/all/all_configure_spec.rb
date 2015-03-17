require_relative '../spec_helper.rb'

describe service('xinetd') do
  it { should be_enabled }
end

describe port(10_080) do
  it { should be_listening.with('tcp') }
end

describe 'connect amanda_server' do
  servers = property[:servers]

  servers.each do |svr_name, server|
    hostname = `hostname`.strip
    next unless server[:roles].include?('backup_restore')
    interface = hostname == svr_name.to_s ? '-I lo' : ''
    describe "#{svr_name} access check" do
      describe command("hping3 -S #{server[:private_ip]} -p 10080 -c 5 #{interface}") do
        its(:stdout) { should match /sport=10080 flags=SA/ }
      end
    end
  end
end
