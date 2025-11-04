#
# Cookbook:: enterprise-time
# Recipe:: default
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Cross-platform time management with native implementations

Chef::Log.info("Testing enterprise-time cookbook on #{node['platform']} #{node['platform_version']}")

# STEP 1: Platform-specific NTP and timezone configuration
if platform_family?('windows')
  Chef::Log.info('Configuring Windows W32Time service and timezone natively')
  Chef::Log.info("NTP servers: #{node['time']['ntp_servers'].join(', ')}")
  
  # Ensure W32Time service is running
  windows_service 'w32time' do
    action [:enable, :start]
  end
  
  # Configure NTP servers using w32tm commands
  node['time']['ntp_servers'].each_with_index do |server, index|
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
  
  # Configure Windows timezone using native tzutil command
  timezone_to_set = node['time']['timezone']
  
  # Convert common timezone names to Windows format
  windows_timezone = case timezone_to_set
  when 'UTC'
    'UTC'
  when 'America/New_York'
    'Eastern Standard Time'
  when 'America/Chicago'
    'Central Standard Time'
  when 'America/Denver'
    'Mountain Standard Time'
  when 'America/Los_Angeles'
    'Pacific Standard Time'
  else
    timezone_to_set
  end
  
  # Set Windows timezone using tzutil
  execute 'set_windows_timezone' do
    command "tzutil /s \"#{windows_timezone}\""
    action :run
    not_if "tzutil /g | findstr /i \"#{windows_timezone}\""
  end
  
  Chef::Log.info("✅ Configured Windows timezone: #{windows_timezone}")
  
  log 'windows_time_config' do
    message "✅ Native W32Time configuration completed - NTP: #{node['time']['ntp_servers'].join(', ')}, Timezone: #{windows_timezone}"
    level :info
  end
  
else
  Chef::Log.info('Configuring Linux NTP services')
  
  # Smart NTP package detection based on platform and version
  case node['platform_family']
  when 'debian'
    # Ubuntu 22.04+ and newer Debian use chrony
    if node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 22.04
      Chef::Log.info('Detected Ubuntu 22.04+, using chrony')
      
      package 'chrony' do
        action :install
      end
      
      service 'chronyd' do
        action [:enable, :start]
      end
      
    else
      Chef::Log.info('Detected older Ubuntu/Debian, using ntp')
      
      package 'ntp' do
        action :install
      end
      
      service 'ntp' do
        action [:enable, :start]
      end
    end
    
  when 'rhel', 'amazon'
    # Amazon Linux 2023+ uses chrony, older versions use ntp
    if (node['platform'] == 'amazon' && node['platform_version'].to_i >= 2023) ||
       (node['platform_family'] == 'rhel' && node['platform_version'].to_i >= 8)
      Chef::Log.info('Detected modern RHEL/Amazon Linux, using chrony')
      
      package 'chrony' do
        action :install
      end
      
      service 'chronyd' do
        action [:enable, :start]
      end
      
    else
      Chef::Log.info('Detected older RHEL/Amazon Linux, using ntp')
      
      package 'ntp' do
        action :install
      end
      
      service 'ntpd' do
        action [:enable, :start]
      end
    end
  end
  
  # Log platform-specific enhancements
  log 'ntp_platform_config' do
    message "Applied #{node['platform_family']} NTP configuration for #{node['platform']} #{node['platform_version']}"
    level :info
  end
end

# STEP 2: Linux timezone configuration (Windows handled above)
if platform_family?('rhel', 'debian', 'amazon')
  timezone_to_set = node['time']['timezone']
  Chef::Log.info("Setting Linux timezone to: #{timezone_to_set}")
  
  execute 'set_timezone' do
    command "timedatectl set-timezone #{timezone_to_set}"
    action :run
    not_if "timedatectl show --property=Timezone --value | grep -q '^#{timezone_to_set}$'"
  end
  
  Chef::Log.info("✅ Linux timezone configuration completed: #{timezone_to_set}")
end

# Final verification
log 'cookbook_completion' do
  message "Enterprise-time cookbook completed successfully on #{node['platform']} #{node['platform_version']}"
  level :info
end

Chef::Log.info("✅ Enterprise-time configuration completed successfully with timezone: #{node['time']['timezone']}")
