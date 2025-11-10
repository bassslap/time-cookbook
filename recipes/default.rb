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
  # Add debugging to see what we're actually receiving
  Chef::Log.info("🔍 Windows timezone mapping input: '#{timezone_to_set}' (#{timezone_to_set.class})")
  Chef::Log.info("🔍 All timezone attributes: #{node['time'].to_hash}")
  Chef::Log.info("🔍 Override timezone: #{node.override['time']['timezone'] rescue 'none'}")
  Chef::Log.info("🔍 Default timezone: #{node.default['time']['timezone'] rescue 'none'}")
  
  # PRODUCTION FIX: Force EST mapping to match Test Kitchen behavior
  if timezone_to_set.to_s.strip == 'America/New_York'
    Chef::Log.info("🔧 PRODUCTION FIX: Forcing America/New_York -> Eastern Standard Time")
    windows_timezone = 'Eastern Standard Time'
  else
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
                         # For EST request, default to Eastern Standard Time
                         if timezone_to_set.to_s.strip.downcase.include?('est') || 
                            timezone_to_set.to_s.strip.downcase.include?('eastern')
                           Chef::Log.info("🔧 Detected EST/Eastern request, mapping to Eastern Standard Time")
                           'Eastern Standard Time'
                         else
                           # If we don't recognize it, try to use it as-is but log a warning
                           Chef::Log.warn("⚠️  Unknown timezone '#{timezone_to_set}', using as-is. Consider updating the mapping.")
                           timezone_to_set.to_s.strip
                         end
                     end
  end  Chef::Log.info("🔍 Mapped '#{timezone_to_set}' → '#{windows_timezone}' for Windows")

  # Use PowerShell to set timezone with validation (more reliable than tzutil)
  powershell_script 'set_windows_timezone' do
    code <<-EOH
      Write-Host "Current timezone: $((Get-TimeZone).Id)"
      Write-Host "Target timezone: #{windows_timezone}"

      try {
        $currentTZ = Get-TimeZone
        Write-Host "Current timezone ID: $($currentTZ.Id)"
        
        # Handle special case where target is "Coordinated Universal Time" but should be "UTC"
        $targetTimezone = "#{windows_timezone}"
        if ($targetTimezone -eq "Coordinated Universal Time") {
          Write-Host "Mapping 'Coordinated Universal Time' to 'UTC'"
          $targetTimezone = "UTC"
        }
        
        # First, validate that the target timezone exists
        $targetExists = Get-TimeZone -ListAvailable | Where-Object { $_.Id -eq $targetTimezone }
        if (-not $targetExists) {
          Write-Host "WARNING: Timezone '$targetTimezone' not found. Searching for alternatives..."
          
          # Try to find a close match based on the original request
          if ($targetTimezone -like "*Eastern*" -or "#{windows_timezone}" -eq "Eastern Standard Time") {
            $alternatives = Get-TimeZone -ListAvailable | Where-Object { $_.Id -like "*Eastern*" }
            Write-Host "Looking for Eastern timezone alternatives:"
            $alternatives | ForEach-Object { Write-Host "  ID: '$($_.Id)', Display: '$($_.DisplayName)'" }
            
            $correctId = ($alternatives | Where-Object { $_.Id -eq "Eastern Standard Time" }).Id
            if ($correctId) {
              Write-Host "Using Eastern Standard Time"
              $targetTimezone = "Eastern Standard Time"
            }
          } elseif ($targetTimezone -like "*UTC*" -or $targetTimezone -eq "UTC") {
            # For UTC, just use "UTC"
            Write-Host "Using UTC timezone"
            $targetTimezone = "UTC"
          } else {
            # List available timezones for debugging
            Write-Host "Available timezones containing search term:"
            $allZones = Get-TimeZone -ListAvailable | Where-Object { $_.Id -like "*$targetTimezone*" -or $_.DisplayName -like "*$targetTimezone*" }
            $allZones | ForEach-Object { Write-Host "  ID: '$($_.Id)', Display: '$($_.DisplayName)'" }
            
            if (-not $allZones) {
              throw "No matching timezone found for '$targetTimezone'"
            }
          }
          
          # Validate the final target exists
          $finalExists = Get-TimeZone -ListAvailable | Where-Object { $_.Id -eq $targetTimezone }
          if (-not $finalExists) {
            throw "Final timezone '$targetTimezone' is not available on this system"
          }
        }
      
        if ($currentTZ.Id -ne $targetTimezone) {
          Write-Host "Setting timezone to $targetTimezone..."
          Set-TimeZone -Id $targetTimezone -ErrorAction Stop
          $newTZ = Get-TimeZone
          Write-Host "Successfully set timezone to $($newTZ.Id)"
        } else {
          Write-Host "Timezone already set to $targetTimezone"
        }
      } catch {
        Write-Host "Error setting timezone: $_"
        Write-Host "Listing first 20 available timezones for reference..."
        $allZones = Get-TimeZone -ListAvailable | Sort-Object Id | Select-Object -First 20
        $allZones | ForEach-Object { Write-Host "  ID: '$($_.Id)', Display: '$($_.DisplayName)'" }
        throw "Failed to set timezone to #{windows_timezone}: $_"
      }
    EOH
    action :run
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
  override_tz = node.override['time'] && node.override['time']['timezone'] && !node.override['time']['timezone'].empty? ? node.override['time']['timezone'] : nil
  default_tz = node.default['time'] && node.default['time']['timezone'] && !node.default['time']['timezone'].empty? ? node.default['time']['timezone'] : nil
  
  if desired_timezone == 'UTC' && (override_tz || default_tz)
    # Use the explicitly configured timezone instead of automatic UTC
    timezone_to_set = override_tz || default_tz
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
