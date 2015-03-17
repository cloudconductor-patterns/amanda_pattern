require_relative '../spec_helper.rb'

describe service('xinetd') do
  it { should be_enabled }
end

describe port(10_080) do
  it { should be_listening.with('tcp') }
end
