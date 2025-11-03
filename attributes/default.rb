# Default attributes for time-cookbook

# Timezone configuration
default['time']['timezone'] = 'UTC'

# NTP servers - use platform-specific defaults
default['time']['ntp_servers'] = case node['platform_family']
                                 when 'windows'
                                   [
                                     'time.windows.com',
                                     'time.nist.gov',
                                     'pool.ntp.org',
                                   ]
                                 when 'rhel', 'fedora', 'amazon'
                                   [
                                     '0.pool.ntp.org',
                                     '1.pool.ntp.org',
                                     '2.pool.ntp.org',
                                     '3.pool.ntp.org',
                                   ]
                                 else
                                   [
                                     '0.pool.ntp.org',
                                     '1.pool.ntp.org',
                                     '2.pool.ntp.org',
                                     '3.pool.ntp.org',
                                   ]
                                 end

# NTP service configuration
default['time']['ntp_service_enabled'] = true
default['time']['ntp_service_action'] = [:enable, :start]

# Windows specific
default['time']['windows']['w32time_config'] = {
  'NtpServer' => default['time']['ntp_servers'].join(',0x1 ') + ',0x1',
  'Type' => 'NTP',
  'Enabled' => 1,
}

# Linux specific
default['time']['linux']['ntp_conf_template'] = 'ntp.conf.erb'
default['time']['linux']['chrony_conf_template'] = 'chrony.conf.erb'
default['time']['linux']['use_chrony'] = false # Use traditional ntpd by default
default['time']['linux']['prefer_ntpd'] = true # Prefer traditional ntpd over chrony
