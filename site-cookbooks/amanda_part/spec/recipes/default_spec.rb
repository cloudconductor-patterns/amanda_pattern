require_relative '../spec_helper'

describe 'amanda_part::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'include setup recipe' do
    expect(chef_run).to include_recipe 'amanda_part::setup'
  end
end
