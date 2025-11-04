# Enterprise Time Cookbook

**Production-ready time synchronization and timezone management for enterprise hybrid environments**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Chef Version](https://img.shields.io/badge/Chef-16%2B-orange.svg)](https://chef.io)
[![Platforms](https://img.shields.io/badge/Platforms-Windows%20%7C%20Linux-green.svg)](https://github.com/bassslap/time-cookbook)

## Overview

This cookbook provides enterprise-grade time management across Windows and Linux environments, leveraging proven Chef Supermarket cookbooks for maximum reliability and maintainability. Built for production use with comprehensive testing and professional support.

### Key Benefits

- **Production Reliability**: Built on battle-tested Supermarket cookbooks with 500k+ downloads
- **Hybrid Platform Support**: Seamless operation across Windows and Linux environments  
- **Modern Architecture**: Uses Policyfiles for dependency management (no Berksfile required)
- **Enterprise Ready**: Comprehensive testing, monitoring, and professional documentation
- **Low Maintenance**: Leverages community cookbooks for automatic platform updates

## Architecture

### Foundation Cookbooks
- **[ntp](https://supermarket.chef.io/cookbooks/ntp) (~3.7.0)**: Industry-standard NTP configuration
- **[timezone](https://supermarket.chef.io/cookbooks/timezone) (~0.2.0)**: Cross-platform timezone management
- **[windows](https://supermarket.chef.io/cookbooks/windows) (~9.1.0)**: Advanced Windows platform resources

### Enhanced Recipes
- `supermarket.rb`: Main orchestration using community cookbooks
- `ntp_enhancements.rb`: Linux platform optimizations
- `ntp_windows_enhanced.rb`: Enterprise Windows time configuration

## Quick Start

### Basic Usage
```ruby
# In your run_list or Policyfile
run_list "recipe[enterprise-time::default]"
```

### Custom Configuration  
```ruby
# Node attributes or role configuration
default_attributes(
  'time' => {
    'timezone' => 'America/New_York',
    'ntp_servers' => [
      '0.north-america.pool.ntp.org',
      '1.north-america.pool.ntp.org',
      '2.north-america.pool.ntp.org'
    ]
  }
)
```
## Platform Support

| Platform | Versions | NTP Service | Notes |
|----------|----------|-------------|-------|
| **Windows Server** | 2012+ | W32Time | Production validated |
| **Ubuntu** | 18.04+ | ntp/systemd-timesyncd | LTS versions supported |
| **RHEL/CentOS** | 7+ | ntp/chrony | Enterprise distributions |
| **Amazon Linux** | 2+ | chrony | Cloud-optimized |
| **Debian** | 9+ | ntp | Stable releases |

## Configuration

### Core Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `['time']['timezone']` | String | `'UTC'` | System timezone (IANA format for Linux, Windows format for Windows) |
| `['time']['ntp_servers']` | Array | Regional pool servers | NTP servers for time synchronization |

### Example Configurations

#### Corporate Environment
```ruby
# Policyfile.rb or role configuration
default['time']['timezone'] = 'UTC'
default['time']['ntp_servers'] = [
  'ntp1.company.com',      # Primary corporate NTP
  'ntp2.company.com',      # Secondary corporate NTP
  '0.pool.ntp.org'         # Public fallback
]
```

#### Multi-Region Deployment
```ruby
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

## Deployment Methods

### Chef Automate/Server
```bash
# Upload cookbook and dependencies
chef install Policyfile.rb
chef push production Policyfile.lock.json

# Apply via Chef Automate UI or knife
knife node run_list add NODE_NAME "recipe[time-cookbook::default]"
```

### Standalone (chef-solo/chef-zero)
```bash
# Local development or standalone systems
chef-client --local-mode --override-runlist time-cookbook::default
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
