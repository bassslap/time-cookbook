#
# Cookbook:: time-cookbook
# Recipe:: ntp_linux
#
# Copyright:: 2025, Your Name, All Rights Reserved.
#
# Configures NTP service on Linux systems (defaults to traditional ntpd)

ntp_servers = node['time']['ntp_servers']
use_chrony = node['time']['linux']['use_chrony']
prefer_ntpd = node['time']['linux']['prefer_ntpd']

# Use traditional ntpd by default, unless explicitly configured to use chrony
if use_chrony && !prefer_ntpd
  include_recipe 'time-cookbook::chrony'
else
  include_recipe 'time-cookbook::ntp_daemon'
end

Chef::Log.info("Linux NTP configured with traditional ntpd using servers: #{ntp_servers.join(', ')}")