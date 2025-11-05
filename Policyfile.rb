# Enterprise-time cookbook Policyfile - standalone with no external dependencies
name 'enterprise_time_policy'

# Default run list
run_list 'enterprise-time::default'

# Local cookbook only
cookbook 'enterprise-time', path: '.'

# Default attributes - easily configurable
# To use different timezone: change this line and run 'chef update'
# Common options: 'America/New_York' (EST/EDT), 'America/Chicago' (CST/CDT), 'UTC', etc.
# Using override to beat automatic attributes (AWS sets automatic timezone to UTC)
override['time']['timezone'] = 'America/New_York'  # EST/EDT timezone
default['time']['ntp_servers'] = [
  '0.pool.ntp.org',
  '1.pool.ntp.org',
  '2.pool.ntp.org',
  '3.pool.ntp.org',
]
default['time']['ntp_service_enabled'] = true
