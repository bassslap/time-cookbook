#
# Cookbook:: enterprise-time
# Recipe:: default
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Simple time management using proven Supermarket cookbooks

# STEP 1: Configure NTP services FIRST for accurate time synchronization
if platform_family?('windows')
  include_recipe 'enterprise-time::ntp_windows_enhanced'
else
  include_recipe 'ntp::default'
  include_recipe 'enterprise-time::ntp_enhancements'
end

# STEP 2: Configure timezone AFTER NTP is running
include_recipe 'timezone::default'
