#
# Cookbook:: time-cookbook
# Recipe:: ntp_daemon
#
# Copyright:: 2025, Your Name, All Rights Reserved.
#
# Configures traditional ntpd service (now the default choice)

ntp_servers = node['time']['ntp_servers']

# Determine the correct ntp package name based on platform
ntp_package = case node['platform_family']
              when 'debian'
                'ntp'
              when 'rhel', 'fedora', 'amazon'
                'ntp'
              when 'suse'
                'ntp'
              else
                'ntp'
              end

# Install NTP package
package ntp_package do
  action :install
end

# Ensure chrony is not running (conflicts with ntpd)
service 'chronyd' do
  action [:stop, :disable]
  only_if { ::File.exist?('/etc/init.d/chronyd') || ::File.exist?('/usr/lib/systemd/system/chronyd.service') || ::File.exist?('/lib/systemd/system/chronyd.service') }
end

# Remove chrony package if it's installed to prevent conflicts
package 'chrony' do
  action :remove
  only_if 'which chronyd'
  not_if { node['time']['linux']['keep_chrony_installed'] }
end

# Configure NTP
template '/etc/ntp.conf' do
  source 'ntp.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    ntp_servers: ntp_servers
  )
  notifies :restart, 'service[ntpd]', :delayed
end

# Determine the correct service name
ntp_service_name = case node['platform_family']
                   when 'debian'
                     'ntp'
                   when 'rhel', 'fedora', 'amazon'
                     'ntpd'
                   else
                     'ntpd'
                   end

# Start and enable NTP service
service ntp_service_name do
  service_name ntp_service_name
  action [:enable, :start]
  supports restart: true, reload: true, status: true
end

# Force time sync after service is running
execute 'ntp_sync' do
  command 'ntpq -p'
  action :run
  only_if "systemctl is-active #{ntp_service_name} 2>/dev/null || service #{ntp_service_name} status 2>/dev/null"
end

Chef::Log.info("Traditional NTP daemon configured with servers: #{ntp_servers.join(', ')}")