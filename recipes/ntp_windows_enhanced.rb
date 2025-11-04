#
# Cookbook:: enterprise-time
# Recipe:: ntp_windows_enhanced
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Simple Windows time synchronization

ntp_servers = node['time']['ntp_servers']

# Configure W32Time registry settings
windows_registry 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' do
  values [
    { name: 'NtpServer', type: :string, data: ntp_servers.map { |s| "#{s},0x1" }.join(' ') },
    { name: 'Type', type: :string, data: 'NTP' },
  ]
  action :create
  notifies :restart, 'windows_service[w32time]', :delayed
end

# Enhanced W32Time configuration for better reliability
windows_registry 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config' do
  values [
    { name: 'MaxPosPhaseCorrection', type: :dword, data: 172800 },
    { name: 'MaxNegPhaseCorrection', type: :dword, data: 172800 },
    { name: 'AnnounceFlags', type: :dword, data: 10 },
    { name: 'MaxPollInterval', type: :dword, data: 10 },
    { name: 'MinPollInterval', type: :dword, data: 6 },
  ]
  action :create
  notifies :restart, 'windows_service[w32time]', :delayed
end

# Use windows cookbook for enhanced service management
windows_service 'w32time' do
  action [:enable, :start]
  startup_type :automatic
  run_as_user 'LocalSystem'
end

# Force immediate time synchronization with error handling
powershell_script 'force_time_sync' do
  code <<-EOH
    try {
      # Wait for service to be fully started
      Start-Sleep -Seconds 3
    #{'  '}
      # Force time synchronization
      w32tm /resync /force
    #{'  '}
      # Verify synchronization
      $status = w32tm /query /status
      Write-Host "Time synchronization status: $status"
    #{'  '}
      # Log successful configuration
      Write-EventLog -LogName System -Source "Chef" -EventId 1001 -Message "W32Time configured successfully with NTP servers: #{ntp_servers.join(', ')}" -EntryType Information
    #{'  '}
    } catch {
      Write-Error "Time synchronization failed: $($_.Exception.Message)"
      Write-EventLog -LogName System -Source "Chef" -EventId 1002 -Message "W32Time configuration failed: $($_.Exception.Message)" -EntryType Warning
    }
  EOH
  action :run
  only_if { ::Win32::Service.status('w32time')['current_state'] == 'running' }
end

Chef::Log.info("Windows time service configured successfully with #{ntp_servers.length} NTP servers")
