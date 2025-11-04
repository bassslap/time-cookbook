#
# Cookbook:: enterprise-time
# Attributes:: default
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Production-ready time management attributes with intelligent platform defaults

# Core time configuration
default['time']['timezone'] = 'UTC'
default['time']['ntp_service_enabled'] = true

# Intelligent NTP server selection based on platform and region
default['time']['ntp_servers'] = case node['platform_family']
                                 when 'windows'
                                   # Windows-optimized time sources
                                   [
                                     'time.windows.com',
                                     'time.nist.gov',
                                     '0.pool.ntp.org',
                                   ]
                                 when 'amazon'
                                   # AWS-optimized time sources
                                   [
                                     '169.254.169.123', # Amazon Time Sync Service
                                     '0.amazon.pool.ntp.org',
                                     '1.amazon.pool.ntp.org',
                                   ]
                                 else
                                   # Global pool servers for maximum reliability
                                   [
                                     '0.pool.ntp.org',
                                     '1.pool.ntp.org',
                                     '2.pool.ntp.org',
                                     '3.pool.ntp.org',
                                   ]
                                 end

# Windows-specific enterprise configuration
default['time']['windows']['w32time_config'] = {
  'NtpServer' => default['time']['ntp_servers'].map { |s| "#{s},0x1" }.join(' '),
  'Type' => 'NTP',
  'Enabled' => 1,
  'InputProvider' => 1,
  'MaxPosPhaseCorrection' => 172800, # 48 hours in seconds
  'MaxNegPhaseCorrection' => 172800,
}

# Enterprise monitoring and logging
default['time']['monitoring'] = {
  'enable_event_logging' => true,
  'log_time_adjustments' => true,
  'verify_sync_status' => true,
}

# Regional NTP pool overrides for enterprise deployments
# These can be customized per environment in Chef Automate/Server
default['time']['regional_pools'] = {
  'north_america' => %w(0.north-america.pool.ntp.org 1.north-america.pool.ntp.org),
  'europe' => %w(0.europe.pool.ntp.org 1.europe.pool.ntp.org),
  'asia' => %w(0.asia.pool.ntp.org 1.asia.pool.ntp.org),
}
