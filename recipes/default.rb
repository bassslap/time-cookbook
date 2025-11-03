#
# Cookbook:: time-cookbook
# Recipe:: default
#
# Copyright:: 2025, Your Name, All Rights Reserved.
#
# Main recipe that configures timezone and NTP for both Windows and Linux

Chef::Log.info("Configuring time settings for #{node['platform']} (#{node['platform_family']})")

# Set timezone
include_recipe 'time-cookbook::timezone'

# Configure NTP
include_recipe 'time-cookbook::ntp'

Chef::Log.info("Time configuration completed successfully")