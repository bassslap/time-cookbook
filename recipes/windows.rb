#
# Cookbook:: enterprise-time
# Recipe:: windows
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Windows-specific time and timezone configuration

Chef::Log.info('Configuring Windows W32Time service and timezone natively')
Chef::Log.info("NTP servers: #{node['time']['ntp_servers'].join(', ')}")

# Ensure W32Time service is running
windows_service 'w32time' do
  action [:enable, :start]
end

# Configure NTP servers using w32tm commands
node['time']['ntp_servers'].each_with_index do |_server, index|
  execute "configure_ntp_server_#{index}" do
    command "w32tm /config /manualpeerlist:\"#{node['time']['ntp_servers'].join(' ')}\" /syncfromflags:manual /reliable:yes /update"
    action :run
    only_if { index == 0 } # Only run once with all servers
  end
end

# Restart W32Time to apply configuration
execute 'restart_w32time' do
  command 'net stop w32time && net start w32time'
  action :run
end

# Force time synchronization
execute 'sync_time' do
  command 'w32tm /resync'
  action :run
end

Chef::Log.info("✅ Configured W32Time with NTP servers: #{node['time']['ntp_servers'].join(', ')}")

# Configure critical W32Time registry settings
registry_key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' do
  values [
    { name: 'NoModifySystemTime', type: :dword, data: 0 },
  ]
  action :create
  notifies :restart, 'windows_service[w32time]', :delayed
end

Chef::Log.info('✅ Set NoModifySystemTime registry value to 0')

# Configure W32Time for better synchronization accuracy
registry_key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config' do
  values [
    { name: 'MaxPosPhaseCorrection', type: :dword, data: 172800 },
    { name: 'MaxNegPhaseCorrection', type: :dword, data: 172800 },
    { name: 'AnnounceFlags', type: :dword, data: 5 },
    { name: 'MinPollInterval', type: :dword, data: 6 },
    { name: 'MaxPollInterval', type: :dword, data: 10 },
  ]
  action :create
  notifies :restart, 'windows_service[w32time]', :delayed
end

Chef::Log.info('✅ Configured W32Time advanced settings for better accuracy')

# ============================================================================
# TIMEZONE CONFIGURATION - Using Chef Built-in Resource
# ============================================================================
# Chef Infra Client provides a native 'timezone' resource that handles
# timezone configuration across all platforms (Windows, Linux, macOS)
# Documentation: https://docs.chef.io/resources/timezone/
# ============================================================================

timezone_to_set = node['time']['timezone']

# Map common timezone formats to Windows timezone IDs
windows_timezone = case timezone_to_set.to_s.strip
                   when 'UTC', 'Coordinated Universal Time'
                     'UTC'
                   when 'America/New_York', 'Eastern Standard Time', 'EST', 'Eastern'
                     'Eastern Standard Time'
                   when 'America/Chicago', 'Central Standard Time', 'CST', 'Central'
                     'Central Standard Time'
                   when 'America/Denver', 'Mountain Standard Time', 'MST', 'Mountain'
                     'Mountain Standard Time'
                   when 'America/Los_Angeles', 'Pacific Standard Time', 'PST', 'Pacific'
                     'Pacific Standard Time'
                   when 'America/Phoenix'
                     'US Mountain Standard Time'
                   when 'Europe/London', 'GMT'
                     'GMT Standard Time'
                   when 'Europe/Paris', 'Europe/Berlin', 'CET'
                     'W. Europe Standard Time'
                   when 'Asia/Tokyo', 'JST'
                     'Tokyo Standard Time'
                   when 'Australia/Sydney'
                     'AUS Eastern Standard Time'
                   else
                     # Use as-is if already in Windows format
                     timezone_to_set.to_s.strip
                   end

Chef::Log.info("Setting Windows timezone from '#{timezone_to_set}' to '#{windows_timezone}'")

# *** CHEF BUILT-IN RESOURCE ***
# Using Chef Infra Client's native timezone resource (no external dependency)
timezone windows_timezone do
  action :set
end
# *** END CHEF BUILT-IN RESOURCE ***

Chef::Log.info("✅ Configured Windows timezone: #{windows_timezone}")

# Verify W32Time service is running and configured properly
execute 'verify_w32time_status' do
  command 'w32tm /query /status'
  action :run
end

# Final time synchronization and verification
execute 'final_time_sync' do
  command 'w32tm /resync /force'
  action :run
  retries 3
  retry_delay 5
end

Chef::Log.info('✅ Completed comprehensive Windows time configuration')

log 'windows_time_config' do
  message "✅ W32Time configuration completed - NTP: #{node['time']['ntp_servers'].join(', ')}, Timezone: #{windows_timezone}"
  level :info
end
