#
# Cookbook:: enterprise-time
# Recipe:: ntp_enhancements
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Simple NTP optimizations for Linux platforms

# Platform-specific optimizations
case node['platform_family']
when 'debian'
  execute 'verify_ntp_service' do
    command 'systemctl is-active ntp || systemctl is-active ntpd'
    action :run
    ignore_failure true
  end

when 'rhel', 'amazon'
  execute 'sync_hardware_clock' do
    command 'hwclock --systohc'
    action :run
    ignore_failure true
  end
end
