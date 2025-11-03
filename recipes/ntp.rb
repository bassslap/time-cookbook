#
# Cookbook:: time-cookbook
# Recipe:: ntp
#
# Copyright:: 2025, Your Name, All Rights Reserved.
#
# Configures NTP service on Windows and Linux

case node['platform_family']
when 'windows'
  include_recipe 'time-cookbook::ntp_windows'
else
  include_recipe 'time-cookbook::ntp_linux'
end

Chef::Log.info("NTP configuration completed")