# Time Cookbook

A Chef cookbook for configuring system timezone and NTP services on both Windows and Linux platforms.

## Description

This cookbook provides a comprehensive solution for managing time synchronization across different operating systems. It handles timezone configuration and NTP service setup for:

- **Windows**: Uses W32Time service with configurable NTP servers
- **Linux**: Uses traditional `ntpd` service by default (with optional `chrony` support)

## Requirements

### Platform Support

- Windows (all supported versions)
- Ubuntu (16.04+)
- Debian (8+)
- RHEL/CentOS (6+)
- Fedora (recent versions)
- Amazon Linux
- SUSE

### Chef Version

- Chef 16.0 or later

## Attributes

### Default Attributes

| Attribute | Default Value | Description |
|-----------|---------------|-------------|
| `node['time']['timezone']` | `'UTC'` | System timezone to set |
| `node['time']['ntp_servers']` | Platform-specific pool servers | Array of NTP servers |
| `node['time']['ntp_service_enabled']` | `true` | Enable NTP service |
| `node['time']['linux']['use_chrony']` | `false` | Use chrony instead of ntpd on Linux |
| `node['time']['linux']['prefer_ntpd']` | `true` | Prefer traditional ntpd over chrony |

### Windows-specific Attributes

| Attribute | Default Value | Description |
|-----------|---------------|-------------|
| `node['time']['windows']['w32time_config']['NtpServer']` | Comma-separated server list | W32Time NTP server configuration |
| `node['time']['windows']['w32time_config']['Type']` | `'NTP'` | W32Time service type |

### Linux-specific Attributes

| Attribute | Default Value | Description |
|-----------|---------------|-------------|
| `node['time']['linux']['ntp_conf_template']` | `'ntp.conf.erb'` | Template for ntpd configuration |
| `node['time']['linux']['chrony_conf_template']` | `'chrony.conf.erb'` | Template for chrony configuration |

## Usage

### Basic Usage

Add the cookbook to your node's run list:

```ruby
run_list "recipe[time-cookbook::default]"
```

### Custom Configuration

Set timezone and NTP servers in your node attributes or roles:

```ruby
# In a role or node attributes
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

### Using Chrony on Linux

To use chrony instead of traditional ntpd (if needed for specific requirements):

```ruby
default_attributes(
  'time' => {
    'linux' => {
      'use_chrony' => true,
      'prefer_ntpd' => false
    }
  }
)
```

### Windows-specific Configuration

```ruby
default_attributes(
  'time' => {
    'timezone' => 'Pacific Standard Time',
    'ntp_servers' => [
      'time.windows.com',
      'time.nist.gov'
    ]
  }
)
```

## Recipes

### default

Main recipe that includes timezone and NTP configuration.

### timezone

Configures system timezone on both Windows and Linux.

### ntp

Main NTP recipe that delegates to platform-specific implementations.

### ntp_windows

Configures Windows Time (W32Time) service.

### ntp_linux

Determines whether to use traditional ntpd (default) or chrony and includes appropriate recipe.

### chrony

Configures chrony NTP service (modern replacement for ntpd).

### ntp_daemon

Configures traditional ntpd service (now the default choice).

## Testing

This cookbook includes comprehensive test suites:

### Test Kitchen

Run integration tests with Test Kitchen:

```bash
# List available test instances
kitchen list

# Test all platforms
kitchen test

# Test specific platform
kitchen test ubuntu-2004-default
kitchen test windows-2019-windows
```

### InSpec Tests

The cookbook includes InSpec tests that verify:

- NTP service is installed, enabled, and running
- Timezone is correctly configured
- Configuration files are properly generated
- Services are responding correctly

## Platform-specific Behavior

### Windows

- Uses PowerShell scripts for configuration
- Configures W32Time service
- Supports Windows timezone names (e.g., "Pacific Standard Time")
- Automatically handles service restart and synchronization

### Linux

#### Modern Systems (systemd)
- Uses `timedatectl` for timezone configuration when available
- Supports both chrony and ntpd
- Automatically detects and uses appropriate service manager

#### Legacy Systems
- Falls back to manual timezone file management
- Uses traditional service commands
- Maintains compatibility with older distributions

#### RHEL/CentOS 8+
- Uses traditional ntpd by default (changed from chrony)
- Disables conflicting chrony service if present
- Can be configured to use chrony if specifically needed

#### Debian/Ubuntu
- Supports both ntpd and chrony
- Uses `dpkg-reconfigure tzdata` for timezone on older systems

## Common Timezone Examples

### Windows Timezone Names
- `"UTC"`
- `"Pacific Standard Time"`
- `"Eastern Standard Time"`
- `"Central Standard Time"`
- `"Mountain Standard Time"`

### Linux Timezone Names
- `"UTC"`
- `"America/New_York"`
- `"America/Chicago"`
- `"America/Denver"`
- `"America/Los_Angeles"`
- `"Europe/London"`
- `"Asia/Tokyo"`

## Troubleshooting

### Windows

Check W32Time status:
```powershell
w32tm /query /status
w32tm /query /peers
```

### Linux

Check NTP service status:
```bash
# For chrony
chrony sources -v
systemctl status chronyd

# For ntpd
ntpq -p
systemctl status ntpd
```

Check timezone:
```bash
timedatectl status  # systemd systems
cat /etc/timezone   # legacy systems
```

## License and Authors

- **Author**: Your Name
- **License**: Apache 2.0

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for any new functionality
5. Ensure all tests pass
6. Submit a pull request

## Changelog

### Version 1.0.0
- Initial release
- Support for Windows and Linux platforms
- Timezone and NTP configuration
- Comprehensive test suite
