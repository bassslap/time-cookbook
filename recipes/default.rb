#
# Cookbook:: enterprise-time
# Recipe:: default
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Cross-platform time management with smart NTP detection

Chef::Log.info("Testing enterprise-time cookbook on #{node['platform']} #{node['platform_version']}")

# STEP 1: Smart NTP platform detection and setup
if platform_family?('windows')
  Chef::Log.info('Configuring Windows W32Time service')
  Chef::Log.info("NTP servers: #{node['time']['ntp_servers'].join(', ')}")
  
  # Simulate Windows registry configuration
  log 'windows_ntp_config' do
    message "Would configure W32Time with servers: #{node['time']['ntp_servers'].join(' ')}"
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

# STEP 2: Timezone configuration
timezone_to_set = node['time']['timezone']
Chef::Log.info("Setting timezone to: #{timezone_to_set}")

# Set timezone using timedatectl on Linux
if platform_family?('rhel', 'debian', 'amazon')
  execute 'set_timezone' do
    command "timedatectl set-timezone #{timezone_to_set}"
    action :run
    not_if "timedatectl show --property=Timezone --value | grep -q '^#{timezone_to_set}$'"
  end
end

# Final verification
log 'cookbook_completion' do
  message "Enterprise-time cookbook completed successfully on #{node['platform']} #{node['platform_version']}"
  level :info
end

Chef::Log.info("✅ Time configuration completed with timezone: #{timezone_to_set}")
