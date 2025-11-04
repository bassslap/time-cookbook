# Standalone testing Policyfile - no external dependencies
name 'enterprise_time_policy'

# Test our simplified cookbook directly
run_list 'enterprise-time::default'

# Only our local cookbook
cookbook 'enterprise-time', path: '.'

# Test attributes  
default['time']['timezone'] = 'America/New_York'
default['time']['ntp_servers'] = [
  '0.pool.ntp.org',
  '1.pool.ntp.org'
]
default['time']['ntp_service_enabled'] = true
