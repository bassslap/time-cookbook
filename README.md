# Enterprise Time Cookbook

**Production-ready time synchronization and timezone management for modern enterprise environments**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Chef Version](https://img.shields.io/badge/Chef-16%2B-orange.svg)](https://chef.io)

## Overview

Enterprise-grade time management cookbook for hybrid Windows/Linux environments. Features native implementations with Chef's built-in resources and the chrony supermarket cookbook.

### Key Features

- ✅ **Native Chef Resources**: Uses Chef's built-in `timezone` resource
- ✅ **Modern Platforms**: Ubuntu 22.04+, Amazon Linux 2023+, Windows Server 2022+
- ✅ **Chrony Integration**: Leverages chrony supermarket cookbook for Linux NTP
- ✅ **W32Time Native**: Direct Windows time service management
- ✅ **Simplified Architecture**: Clean separation between Windows and Linux recipes

## Platform Support

| Platform | Versions | NTP Service | Timezone Management |
|----------|----------|-------------|---------------------|
| **Windows Server** | 2022+ | W32Time (native) | Chef `timezone` resource |
| **Ubuntu** | 22.04+ | chrony | Chef `timezone` resource |
| **Amazon Linux** | 2023+ | chrony | Chef `timezone` resource |
| **RHEL/Rocky** | 8+ | chrony | Chef `timezone` resource |

## Quick Start

### 1. Add to Policyfile

```ruby
# Policyfile.rb
name 'production_policy'

default_source :supermarket

run_list 'enterprise-time::default'

cookbook 'enterprise-time', path: '.'

# Configure timezone and NTP servers
override['time']['timezone'] = 'America/New_York'
default['time']['ntp_servers'] = [
  '0.pool.ntp.org',
  '1.pool.ntp.org',
  '2.pool.ntp.org',
  '3.pool.ntp.org'
]
```

### 2. Update and Upload Policy

```bash
# Update the policy lock
chef update Policyfile.rb

# Push to Chef Server
chef push production Policyfile.rb
```

### 3. Apply to Nodes

```bash
# Set policy on a node
knife node policy set node-linux-04 production production_policy

# Or during bootstrap
knife bootstrap 10.10.3.4 -N node-linux-04 -U ubuntu --sudo \\
  -i ~/.ssh/sys_admin.pem \\
  --policy-name production \\
  --policy-group production_policy
```

## Configuration

### Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `['time']['timezone']` | String | `'America/New_York'` | Timezone (IANA format for Linux, Windows ID for Windows) |
| `['time']['ntp_servers']` | Array | `['0.pool.ntp.org', ...]` | NTP servers for time synchronization |

### Timezone Format Examples

**Linux (IANA format):**
- `America/New_York` - Eastern Time
- `America/Chicago` - Central Time
- `America/Los_Angeles` - Pacific Time
- `UTC` - Coordinated Universal Time

**Windows (Windows Time Zone ID):**
- `Eastern Standard Time`
- `Central Standard Time`
- `Pacific Standard Time`
- `UTC`

The cookbook automatically maps common IANA formats to Windows IDs.

## Usage Examples

### Basic Policy Setup

```ruby
# Policyfile.rb - Simple production policy
name 'production_policy'
default_source :supermarket
run_list 'enterprise-time::default'
cookbook 'enterprise-time', path: '.'

override['time']['timezone'] = 'America/New_York'
default['time']['ntp_servers'] = ['0.pool.ntp.org', '1.pool.ntp.org']
```

### Corporate NTP Servers

```ruby
# Use corporate NTP infrastructure
default['time']['ntp_servers'] = [
  'ntp1.company.com',
  'ntp2.company.com',
  '0.pool.ntp.org'  # Public fallback
]
```

### Multi-Region Deployment

```ruby
# Different policies for different regions
# Policyfile-east.rb
override['time']['timezone'] = 'America/New_York'
default['time']['ntp_servers'] = ['0.north-america.pool.ntp.org']

# Policyfile-west.rb
override['time']['timezone'] = 'America/Los_Angeles'
default['time']['ntp_servers'] = ['0.north-america.pool.ntp.org']
```

### Bootstrap Examples

**Linux Node:**
```bash
knife bootstrap 10.10.3.4 -N node-linux-04 -U ubuntu --sudo \\
  -i ~/.ssh/sys_admin.pem \\
  -r "recipe[enterprise-time]"
```

**Windows Node:**
```bash
knife bootstrap 10.10.3.7 -N node-win-01 -U administrator \\
  -P 'password' --connection-protocol winrm \\
  -r "recipe[enterprise-time]"
```

### Apply Policy to Existing Nodes

```bash
# Set policy on multiple nodes
knife node policy set node-linux-04 production combined_policy
knife node policy set node-linux-05 production combined_policy
knife node policy set node-win-01 production combined_policy

# Trigger Chef run
knife ssh "policy_name:production" "sudo chef-client" -x ubuntu -i ~/.ssh/sys_admin.pem
```

## Recipes

- **`default.rb`**: Platform detection and includes appropriate recipe
- **`linux.rb`**: Linux-specific configuration (chrony + timezone)
- **`windows.rb`**: Windows-specific configuration (W32Time + timezone)

## Dependencies

- **chrony** (`~> 1.2.6`) - Supermarket cookbook for Linux NTP management

## Testing

### Test Kitchen

```bash
# List instances
kitchen list

# Test Linux
kitchen converge default-amazon-linux-2023
kitchen verify default-amazon-linux-2023

# Test Windows (requires AWS setup)
kitchen converge default-windows-2022
```

### Supported Test Platforms

- Amazon Linux 2023
- Ubuntu 22.04
- Windows Server 2022

## Architecture

### Linux (Ubuntu 22.04+, Amazon Linux 2023+)
1. **Chrony Supermarket Cookbook** manages NTP service and configuration
2. **Chef timezone resource** sets system timezone
3. Idempotent and follows Chef best practices

### Windows (Server 2022+)
1. **Native W32Time** service configuration via registry
2. **w32tm** commands for NTP server configuration
3. **Chef timezone resource** sets system timezone
4. Full time synchronization and verification

## License

Apache License 2.0

## Maintainer

Progress Software Corporation - SA Team
# US East Coast
default['time']['timezone'] = 'America/New_York'
default['time']['ntp_servers'] = [
  '0.north-america.pool.ntp.org',
  '1.north-america.pool.ntp.org'
]

# Europe
default['time']['timezone'] = 'Europe/London'  
default['time']['ntp_servers'] = [
  '0.europe.pool.ntp.org',
  '1.europe.pool.ntp.org'
]
```

## Timezone Configuration Deep Dive

### Smart Timezone Management

The cookbook uses intelligent timezone detection and idempotent configuration:

```ruby
# Linux timezone logic (lines 247-249 in recipes/default.rb)
execute 'set_timezone' do
  command "timedatectl set-timezone #{timezone_to_set}"
  action :run
  not_if "timedatectl show --property=Timezone --value | grep -q '^#{timezone_to_set}$'"
end
```

**How the `not_if` Guard Works:**
1. **Check Current**: `timedatectl show --property=Timezone --value` returns current timezone
2. **Compare**: `grep -q` checks if it exactly matches desired timezone
3. **Decision Logic**:
   - ✅ **Match found** → Skip timezone change (already correct)
   - 🔄 **No match** → Set timezone to desired value
4. **Result**: Idempotent - only changes when necessary

### EST/EDT Configuration Examples

#### Option 1: Edit Policyfile.rb (Recommended)
```ruby
# /path/to/cookbook/Policyfile.rb
default['time']['timezone'] = 'America/New_York'  # EST/EDT

# Then update and deploy:
# chef update && chef push production
```

#### Option 2: Node/Role Attributes
```ruby
# In a role or node definition
default_attributes(
  'time' => {
    'timezone' => 'America/New_York',
    'ntp_servers' => [
      '0.north-america.pool.ntp.org',
      '1.north-america.pool.ntp.org'
    ]
  }
)
```

#### Option 3: Kitchen Testing Override
```yaml
# .kitchen.yml
suites:
  - name: est-testing
    attributes:
      time:
        timezone: "America/New_York"
```

### Common Timezone Values

| Region | IANA Format (Linux) | Windows Format | Notes |
|--------|-------------------|----------------|-------|
| **Eastern** | `America/New_York` | `Eastern Standard Time` | EST/EDT |
| **Central** | `America/Chicago` | `Central Standard Time` | CST/CDT |
| **Mountain** | `America/Denver` | `Mountain Standard Time` | MST/MDT |
| **Pacific** | `America/Los_Angeles` | `Pacific Standard Time` | PST/PDT |
| **UTC** | `UTC` | `UTC` | Universal |
| **London** | `Europe/London` | `GMT Standard Time` | GMT/BST |

### Timezone Validation

The cookbook automatically maps between IANA and Windows formats:

```ruby
# Cross-platform timezone mapping in recipes/default.rb
windows_timezone = case timezone_to_set
when 'America/New_York', 'Eastern Standard Time'
  'Eastern Standard Time'  # Windows format
when 'UTC'
  'UTC'                    # Same on both platforms
# ... more mappings
end
```

## Deployment Methods

### Chef Automate/Server
```bash
# Upload cookbook and dependencies
chef install Policyfile.rb
chef push production Policyfile.lock.json

# Apply via Chef Automate UI or knife
knife node run_list add NODE_NAME "recipe[enterprise-time::default]"
```

### Standalone (chef-solo/chef-zero)
```bash
# Local development or standalone systems
# Local development or standalone systems
chef-client --local-mode --override-runlist enterprise-time::default
```

## Testing & Validation

### Automated Testing
- **Unit Tests**: ChefSpec for recipe logic validation
- **Integration Tests**: InSpec for system state verification  
- **Platform Tests**: Kitchen testing across Windows/Linux
- **CI/CD Pipeline**: GitHub Actions with multi-cloud testing

### Manual Verification

#### Linux Systems
```bash
# Check timezone
timedatectl status

# Verify NTP service
systemctl status ntp
ntpq -p

# Test time synchronization
chronyc sources -v  # if using chrony
```

#### Windows Systems
```powershell
# Check timezone
Get-TimeZone

# Verify W32Time service
Get-Service w32time
w32tm /query /status
w32tm /query /peers
```

## Performance & Security

### Security Features
- **Authenticated NTP**: Support for NTP authentication keys
- **Access Controls**: Restrictive NTP daemon configurations
- **Logging**: Comprehensive audit trails
- **Service Hardening**: Minimal privilege configurations

### Performance Optimizations
- **Fast Convergence**: Burst sync for initial time setting
- **Hardware Clock Sync**: Automatic RTC synchronization
- **Network Efficiency**: Optimized polling intervals
- **Resource Management**: Minimal system impact

## Enterprise Support

### Monitoring Integration
- **System Logs**: Structured logging for SIEM integration
- **Metrics Export**: Time drift and sync status metrics
- **Health Checks**: Built-in service verification
- **Alerting**: Event log integration for monitoring systems

### Compliance
- **Audit Ready**: Comprehensive configuration logging
- **Change Tracking**: All modifications tracked via Chef
- **Standards Compliance**: Follows industry NTP best practices
- **Documentation**: Complete audit trail of time configurations

## Troubleshooting Guide

### Common Issues

1. **Time Sync Failures**
   ```bash
   # Check network connectivity to NTP servers
   ntpdate -q 0.pool.ntp.org
   
   # Verify firewall rules (UDP 123)
   netstat -tulpn | grep :123
   ```

2. **Timezone Issues**
   ```bash
   # Verify timezone database
   timedatectl list-timezones | grep America/New_York
   
   # Check system vs hardware clock
   timedatectl status
   ```

3. **Service Conflicts**
   ```bash
   # Check for conflicting time services
   systemctl list-units --type=service | grep -E "(ntp|chrony|timesyncd)"
   ```

## License & Support

- **License**: Apache 2.0 - Production use permitted
- **Support**: Enterprise support available
- **Documentation**: Complete API reference included
- **Updates**: Regular maintenance and security updates

## Contributing

Professional contributions welcome:
1. Fork repository and create feature branch
2. Implement changes with full test coverage  
3. Update documentation for new features
4. Submit pull request with detailed description

For enterprise support or custom development, contact: devops@yourorganization.com

---

*Built for production reliability using proven Chef Supermarket cookbooks*
