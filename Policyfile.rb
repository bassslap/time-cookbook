# Policyfile for time-cookbook
# This file can be used to deploy the cookbook via Chef Automate

name 'time_policy'

# The run_list to apply to nodes using this policy
run_list 'time-cookbook::default'

# Cookbook:: source - when uploaded to Chef Automate, this will be managed there
cookbook 'time-cookbook', path: '.'

# Default attributes that can be overridden in Chef Automate
default['time']['timezone'] = 'UTC'
default['time']['ntp_servers'] = [
  '0.pool.ntp.org',
  '1.pool.ntp.org',
  '2.pool.ntp.org',
  '3.pool.ntp.org',
]

# These can be customized per environment in Chef Automate
default['time']['ntp_service_enabled'] = true

# Use traditional ntpd by default across all Linux platforms
default['time']['linux']['use_chrony'] = false
default['time']['linux']['prefer_ntpd'] = true

# Platform-specific defaults that work well in most environments
if platform_family?('windows')
  default['time']['ntp_servers'] = [
    'time.windows.com',
    'time.nist.gov',
    'pool.ntp.org',
  ]
end
