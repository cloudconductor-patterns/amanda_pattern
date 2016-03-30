require_relative '../spec_helper.rb'

describe service('xinetd') do
  it { should be_enabled }
end

describe port(10_080) do
  it { should be_listening.with('tcp') }
end

describe 'connect amanda_server' do
  servers = property[:servers]

  servers.each do |_, server|
    next unless server[:roles].include?('backup_restore')

    describe host(server[:private_ip]) do
      it { should be_reachable.with(port: 10080) }
    end
  end
end
