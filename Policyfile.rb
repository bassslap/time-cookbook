# Enterprise-time cookbook Policyfile - standalone with no external dependencies
name 'enterprise_time_policy'

# Default run list
run_list 'enterprise-time::default'

# Local cookbook only
cookbook 'enterprise-time', path: '.'

# Default attributes
default['time']['timezone'] = 'America/New_York'
default['time']['ntp_servers'] = [
  '0.pool.ntp.org',
  '1.pool.ntp.org',
  '2.pool.ntp.org',
  '3.pool.ntp.org',
]
default['time']['ntp_service_enabled'] = true
