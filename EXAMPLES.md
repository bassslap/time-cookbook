# Example usage of time-cookbook

## Basic usage with default settings

```ruby
# In your run_list
run_list "recipe[time-cookbook::default]"
```

## Bootstrap from Chef workstaion

'''
knife bootstrap 10.10.3.7 -N node-win-01 -U ubuntu -P 'yourpassword!' --connection-protocol winrm -r 'recip[enterprise-time]'

knife bootstrap 10.10.3.4 -N node-linux-04 -U ubuntu --sudo -i ~/.ssh/sys_admin.pem -r "recip[enterprise-time]"
'''

## Custom timezone and NTP servers

```ruby
# In a role file (roles/webserver.rb)
name 'webserver'
description 'Web server role with custom time settings'
run_list 'recipe[time-cookbook::default]'

default_attributes(
  'time' => {
    'timezone' => 'America/New_York',
    'ntp_servers' => [
      '0.north-america.pool.ntp.org',
      '1.north-america.pool.ntp.org',
      '2.north-america.pool.ntp.org',
      '3.north-america.pool.ntp.org'
    ]
  }
)
```

## Windows-specific configuration

```ruby
# For Windows nodes
default_attributes(
  'time' => {
    'timezone' => 'Pacific Standard Time',
    'ntp_servers' => [
      'time.windows.com',
      'time.nist.gov',
      'pool.ntp.org'
    ]
  }
)
```

## Linux with chrony

```ruby
# Force use of chrony on Linux systems
default_attributes(
  'time' => {
    'timezone' => 'Europe/London',
    'linux' => {
      'use_chrony' => true
    },
    'ntp_servers' => [
      '0.europe.pool.ntp.org',
      '1.europe.pool.ntp.org',
      '2.europe.pool.ntp.org'
    ]
  }
)
```

## Policyfile example

```ruby
# Policyfile.rb
name 'time_policy'

default_source :supermarket

cookbook 'time-cookbook', path: '.'

run_list 'time-cookbook::default'

default['time']['timezone'] = 'UTC'
default['time']['ntp_servers'] = [
  '0.pool.ntp.org',
  '1.pool.ntp.org',
  '2.pool.ntp.org'
]
```