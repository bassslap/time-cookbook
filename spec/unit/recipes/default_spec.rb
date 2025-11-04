require 'spec_helper'

describe 'enterprise-time::default' do
  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04').converge(described_recipe) }

  it 'includes the timezone recipe' do
    expect(chef_run).to include_recipe('timezone::default')
  end

  it 'includes the ntp recipe' do
    expect(chef_run).to include_recipe('ntp::default')
  end

  it 'includes the ntp enhancements recipe' do
    expect(chef_run).to include_recipe('enterprise-time::ntp_enhancements')
  end
end

describe 'enterprise-time::default on Windows' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'windows', version: '2019').converge(described_recipe)
  end

  it 'includes the timezone recipe' do
    expect(chef_run).to include_recipe('timezone::default')
  end

  it 'includes the Windows NTP enhancements recipe' do
    expect(chef_run).to include_recipe('enterprise-time::ntp_windows_enhanced')
  end
end
