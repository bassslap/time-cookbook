# Production Policyfile for enterprise-time cookbook
# Enterprise time management policy leveraging proven Supermarket cookbooks
#
# Deploy with: chef install && chef push production

name 'enterprise_time_policy'

# Default run list for time management across all platforms
run_list 'enterprise-time::default'

# Local cookbook with Supermarket integration
cookbook 'enterprise-time', path: '.'

# Production dependencies - proven Supermarket cookbooks
cookbook 'ntp', '~> 3.7.0' # 500k+ downloads, industry standard
cookbook 'timezone', '~> 0.2.0'      # Dedicated timezone management
cookbook 'windows', '~> 9.1.0'       # Advanced Windows resources

# Production-ready default attributes
# TIMEZONE CONFIGURATION: Customize per environment
default['time']['timezone'] = 'UTC' # Change to your region
# Examples:
# default['time']['timezone'] = 'America/New_York'    # US Eastern
# default['time']['timezone'] = 'America/Chicago'     # US Central
# default['time']['timezone'] = 'America/Denver'      # US Mountain
# default['time']['timezone'] = 'America/Los_Angeles' # US Pacific
# default['time']['timezone'] = 'Europe/London'       # UK
# default['time']['timezone'] = 'Europe/Berlin'       # Central Europe
# default['time']['timezone'] = 'Asia/Tokyo'          # Japan
# default['time']['timezone'] = 'Australia/Sydney'    # Australia
default['time']['ntp_servers'] = [
  '0.pool.ntp.org',
  '1.pool.ntp.org',
  '2.pool.ntp.org',
  '3.pool.ntp.org',
]

# Enterprise service configuration
default['time']['ntp_service_enabled'] = true

# Platform-specific optimizations for enterprise environments
default['time']['windows']['w32time_config'] = {
  'NtpServer' => 'time.windows.com,0x1 time.nist.gov,0x1 0.pool.ntp.org,0x1',
  'Type' => 'NTP',
}

# Override for different environments:
# Development: chef push development
# Staging: chef push staging
# Production: chef push production
