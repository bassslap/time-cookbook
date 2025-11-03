require 'spec_helper'

describe 'time-cookbook::default' do
  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04').converge(described_recipe) }

  it 'includes the timezone recipe' do
    expect(chef_run).to include_recipe('time-cookbook::timezone')
  end

  it 'includes the ntp recipe' do
    expect(chef_run).to include_recipe('time-cookbook::ntp')
  end
end

describe 'time-cookbook::default on Windows' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'windows', version: '2019').converge(described_recipe)
  end

  it 'includes the timezone recipe' do
    expect(chef_run).to include_recipe('time-cookbook::timezone')
  end

  it 'includes the ntp recipe' do
    expect(chef_run).to include_recipe('time-cookbook::ntp')
  end
end
