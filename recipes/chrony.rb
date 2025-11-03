#
# Cookbook:: time-cookbook
# Recipe:: chrony
#
# Copyright:: 2025, Your Name, All Rights Reserved.
#
# Configures chrony NTP service (modern replacement for ntpd)

ntp_servers = node['time']['ntp_servers']

# Install chrony package
package 'chrony' do
  action :install
end

# Ensure ntpd is not running (conflicts with chrony)
service 'ntpd' do
  action [:stop, :disable]
  only_if { ::File.exist?('/etc/init.d/ntpd') || ::File.exist?('/usr/lib/systemd/system/ntpd.service') }
end

service 'ntp' do
  action [:stop, :disable]
  only_if { ::File.exist?('/etc/init.d/ntp') || ::File.exist?('/usr/lib/systemd/system/ntp.service') }
end

# Configure chrony
template '/etc/chrony.conf' do
  source 'chrony.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    ntp_servers: ntp_servers
  )
  notifies :restart, 'service[chronyd]', :delayed
end

# Start and enable chronyd service
service 'chronyd' do
  action [:enable, :start]
  supports restart: true, reload: true, status: true
end

# Force time sync
execute 'chrony_sync' do
  command 'chrony sources -v'
  action :run
  only_if 'systemctl is-active chronyd'
end

Chef::Log.info("Chrony configured with servers: #{ntp_servers.join(', ')}")