#
# Cookbook:: time-cookbook
# Recipe:: timezone
#
# Copyright:: 2025, Your Name, All Rights Reserved.
#
# Configures system timezone on Windows and Linux

timezone = node['time']['timezone']

case node['platform_family']
when 'windows'
  # Windows timezone configuration
  powershell_script 'set_timezone' do
    code <<-EOH
      try {
        Set-TimeZone -Id "#{timezone}" -ErrorAction Stop
        Write-Host "Timezone set to #{timezone}"
      } catch {
        Write-Error "Failed to set timezone to #{timezone}: $($_.Exception.Message)"
        exit 1
      }
    EOH
    only_if <<-EOH
      $currentTz = Get-TimeZone
      if ($currentTz.Id -ne "#{timezone}") {
        Write-Host "Current timezone is $($currentTz.Id), should be #{timezone}"
        exit 0
      } else {
        Write-Host "Timezone is already set to #{timezone}"
        exit 1
      }
    EOH
  end

else
  # Linux timezone configuration
  case node['platform_family']
  when 'rhel', 'fedora', 'amazon'
    # RHEL-based systems
    execute 'set_timezone_rhel' do
      command "timedatectl set-timezone #{timezone}"
      only_if { ::File.exist?('/usr/bin/timedatectl') }
      not_if "timedatectl status | grep -q 'Time zone: #{timezone}'"
    end
    
    # Fallback for older systems without timedatectl
    file '/etc/timezone' do
      content "#{timezone}\n"
      mode '0644'
      owner 'root'
      group 'root'
      not_if { ::File.exist?('/usr/bin/timedatectl') }
    end
    
    link '/etc/localtime' do
      to "/usr/share/zoneinfo/#{timezone}"
      not_if { ::File.exist?('/usr/bin/timedatectl') }
      only_if { ::File.exist?("/usr/share/zoneinfo/#{timezone}") }
    end

  when 'debian'
    # Debian/Ubuntu systems
    execute 'set_timezone_debian' do
      command "timedatectl set-timezone #{timezone}"
      only_if { ::File.exist?('/usr/bin/timedatectl') }
      not_if "timedatectl status | grep -q 'Time zone: #{timezone}'"
    end
    
    # Fallback for older systems
    file '/etc/timezone' do
      content "#{timezone}\n"
      mode '0644'
      owner 'root'
      group 'root'
      not_if { ::File.exist?('/usr/bin/timedatectl') }
      notifies :run, 'execute[reconfigure_tzdata]', :immediately
    end
    
    execute 'reconfigure_tzdata' do
      command 'dpkg-reconfigure -f noninteractive tzdata'
      action :nothing
      not_if { ::File.exist?('/usr/bin/timedatectl') }
    end
    
    link '/etc/localtime' do
      to "/usr/share/zoneinfo/#{timezone}"
      not_if { ::File.exist?('/usr/bin/timedatectl') }
      only_if { ::File.exist?("/usr/share/zoneinfo/#{timezone}") }
    end

  else
    # Generic Linux systems
    link '/etc/localtime' do
      to "/usr/share/zoneinfo/#{timezone}"
      only_if { ::File.exist?("/usr/share/zoneinfo/#{timezone}") }
    end
    
    file '/etc/timezone' do
      content "#{timezone}\n"
      mode '0644'
      owner 'root'
      group 'root'
    end
  end
end

Chef::Log.info("Timezone configured to: #{timezone}")