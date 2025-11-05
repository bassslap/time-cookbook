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

  # STEP 1: Configure critical W32Time registry settings
  registry_key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' do
    values [
      { name: 'NoModifySystemTime', type: :dword, data: 0 },
    ]
    action :create
    notifies :restart, 'windows_service[w32time]', :delayed
  end

  Chef::Log.info('✅ Set NoModifySystemTime registry value to 0')

  # STEP 2: Configure W32Time for better synchronization accuracy
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

  # STEP 3: Configure Windows timezone using PowerShell (more reliable than tzutil)
  timezone_to_set = node['time']['timezone']

  # First, get list of available timezones and map common names to Windows format
  windows_timezone = case timezone_to_set
                     when 'UTC'
                       'UTC'
                     when 'America/New_York', 'Eastern Standard Time'
                       'Eastern Standard Time'
                     when 'America/Chicago', 'Central Standard Time'
                       'Central Standard Time'
                     when 'America/Denver', 'Mountain Standard Time'
                       'Mountain Standard Time'
                     when 'America/Los_Angeles', 'Pacific Standard Time'
                       'Pacific Standard Time'
                     when 'America/Phoenix'
                       'US Mountain Standard Time'
                     when 'Europe/London'
                       'GMT Standard Time'
                     when 'Europe/Paris', 'Europe/Berlin'
                       'W. Europe Standard Time'
                     when 'Asia/Tokyo'
                       'Tokyo Standard Time'
                     when 'Australia/Sydney'
                       'AUS Eastern Standard Time'
                     else
                       timezone_to_set
                     end

  # Use PowerShell to set timezone (more reliable than tzutil)
  powershell_script 'set_windows_timezone' do
    code <<-EOH
      Write-Host "Current timezone: $((Get-TimeZone).Id)"
      Write-Host "Target timezone: #{windows_timezone}"

      try {
        $currentTZ = Get-TimeZone
        Write-Host "Current timezone ID: $($currentTZ.Id)"
      #{'  '}
        if ($currentTZ.Id -ne "#{windows_timezone}") {
          Write-Host "Setting timezone to #{windows_timezone}..."
          Set-TimeZone -Id "#{windows_timezone}" -ErrorAction Stop
          $newTZ = Get-TimeZone
          Write-Host "Successfully set timezone to $($newTZ.Id)"
        } else {
          Write-Host "Timezone already set to #{windows_timezone}"
        }
      } catch {
        Write-Host "Error setting timezone: $_"
        Write-Host "Attempting to list available timezones..."
        $availableZones = Get-TimeZone -ListAvailable | Where-Object { $_.Id -like "*Eastern*" -or $_.DisplayName -like "*Eastern*" }
        Write-Host "Available Eastern timezones:"
        $availableZones | ForEach-Object { Write-Host "  ID: $($_.Id), Display: $($_.DisplayName)" }
        throw "Failed to set timezone to #{windows_timezone}"
      }
    EOH
    action :run
    # Remove the not_if to force execution and better debugging
  end

  Chef::Log.info("✅ Configured Windows timezone: #{windows_timezone}")

  # STEP 4: Verify W32Time service is running and configured properly
  execute 'verify_w32time_status' do
    command 'w32tm /query /status'
    action :run
  end

  # STEP 5: Final time synchronization and verification
  execute 'final_time_sync' do
    command 'w32tm /resync /force'
    action :run
    retries 3
    retry_delay 5
  end

  Chef::Log.info('✅ Completed comprehensive Windows time configuration')

  log 'windows_time_config' do
    message "✅ Enhanced W32Time configuration completed - NTP: #{node['time']['ntp_servers'].join(', ')}, Timezone: #{windows_timezone}, Registry: Configured"
    level :info
  end

else
  Chef::Log.info('Configuring Linux NTP services')

  # Smart NTP package detection based on platform and version
  case node['platform_family']
  when 'debian'
    # Ubuntu 22.04+ and newer Debian use chrony
    if platform?('ubuntu') && node['platform_version'].to_f >= 22.04
      Chef::Log.info('Detected Ubuntu 22.04+, using chrony')

      package 'chrony' do
        action :install
      end

      # Configure chrony with NTP servers
      template '/etc/chrony.conf' do
        source 'chrony.conf.erb'
        owner 'root'
        group 'root'
        mode '0644'
        variables(
          ntp_servers: node['time']['ntp_servers']
        )
        notifies :restart, 'service[chronyd]', :delayed
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
    if (platform?('amazon') && node['platform_version'].to_i >= 2023) ||
       (platform_family?('rhel') && node['platform_version'].to_i >= 8)
      Chef::Log.info('Detected modern RHEL/Amazon Linux, using chrony')

      package 'chrony' do
        action :install
      end

      # Configure chrony with NTP servers
      template '/etc/chrony.conf' do
        source 'chrony.conf.erb'
        owner 'root'
        group 'root'
        mode '0644'
        variables(
          ntp_servers: node['time']['ntp_servers']
        )
        notifies :restart, 'service[chronyd]', :delayed
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

  # SOLUTION: Bypass automatic attribute precedence by reading from multiple sources
  # Priority: 1) Kitchen attributes, 2) Policyfile attributes, 3) Cookbook defaults
  desired_timezone = node['time']['timezone']

  # On AWS, automatic attributes set timezone to UTC, but we want to honor explicit settings
  # Check if we have an explicit timezone setting (not the automatic UTC)
  if desired_timezone == 'UTC' && (node.override['time']['timezone'] || node.default['time']['timezone'])
    # Use the explicitly configured timezone instead of automatic UTC
    timezone_to_set = node.override['time']['timezone'] || node.default['time']['timezone']
    Chef::Log.info("🔧 Overriding automatic UTC timezone with configured: #{timezone_to_set}")
  else
    timezone_to_set = desired_timezone
  end

  Chef::Log.info("Setting Linux timezone to: #{timezone_to_set}")
  Chef::Log.info("🔍 DEBUG: desired=#{desired_timezone.inspect}, override=#{node.override['time']['timezone'].inspect}, default=#{node.default['time']['timezone'].inspect}")

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
