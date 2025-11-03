#
# Cookbook:: time-cookbook
# Recipe:: ntp_windows
#
# Copyright:: 2025, Your Name, All Rights Reserved.
#
# Configures Windows Time (W32Time) service

ntp_servers = node['time']['ntp_servers']
w32time_config = node['time']['windows']['w32time_config']

# Ensure Windows Time service is running
service 'w32time' do
  action [:enable, :start]
end

# Configure NTP servers
powershell_script 'configure_w32time_ntp' do
  code <<-EOH
    try {
      # Stop the service to make configuration changes
      Stop-Service w32time -Force -ErrorAction SilentlyContinue
      
      # Configure NTP servers
      w32tm /config /manualpeerlist:"#{w32time_config['NtpServer']}" /syncfromflags:manual /reliable:YES /update
      
      # Set service to automatic start
      Set-Service w32time -StartupType Automatic
      
      # Start the service
      Start-Service w32time
      
      # Force immediate sync
      w32tm /resync /force
      
      Write-Host "W32Time configured successfully with servers: #{ntp_servers.join(', ')}"
    } catch {
      Write-Error "Failed to configure W32Time: $($_.Exception.Message)"
      exit 1
    }
  EOH
  notifies :restart, 'service[w32time]', :delayed
end

# Verify NTP configuration
powershell_script 'verify_ntp_config' do
  code <<-EOH
    try {
      $config = w32tm /query /configuration
      $peers = w32tm /query /peers
      Write-Host "Current W32Time configuration:"
      Write-Host $config
      Write-Host "Current peers:"
      Write-Host $peers
    } catch {
      Write-Warning "Could not verify NTP configuration: $($_.Exception.Message)"
    }
  EOH
  action :run
end

Chef::Log.info("Windows NTP (W32Time) configured with servers: #{ntp_servers.join(', ')}")