# NTP Supermarket Cookbook Integration

## Overview

This document describes the integration of the `ntp` supermarket cookbook (version 5.2.5) from Sous Chefs into the `enterprise-time` cookbook for enhanced NTP management on Linux systems.

## What is the NTP Supermarket Cookbook?

- **Maintainer**: Sous Chefs community
- **Version**: 5.2.5 (latest stable)
- **Purpose**: Installs and configures NTP as a client or server
- **Supported Platforms**: Debian, Ubuntu, RHEL, CentOS, Amazon Linux, FreeBSD, Windows, macOS
- **GitHub**: https://github.com/sous-chefs/ntp
- **Supermarket**: https://supermarket.chef.io/cookbooks/ntp

## Integration Approach

We've implemented a **hybrid approach** that:

1. **Windows**: Continues to use native W32Time service implementation
2. **Linux (compatible platforms)**: Uses the NTP supermarket cookbook for robust NTP management
3. **RHEL 8+**: Uses chrony directly (since classic NTP is no longer available)

## Files Modified

### 1. `metadata.rb`
- Added dependency: `depends 'ntp', '~> 5.2.5'`
- Bumped version to 3.2.0

### 2. `Policyfile.rb`
- Added NTP cookbook from supermarket: `cookbook 'ntp', '~> 5.2.5', :supermarket`

### 3. New Recipe: `recipes/with_ntp_supermarket.rb`
- Alternative recipe that uses the NTP supermarket cookbook for Linux
- Maintains Windows W32Time implementation
- Maps our cookbook attributes to NTP cookbook attributes

## How to Use

### Option 1: Use the New Recipe (Recommended for Testing)

Update your Policyfile.rb run list:
```ruby
run_list 'enterprise-time::with_ntp_supermarket'
```

### Option 2: Replace Default Recipe Logic

You can also update the default recipe to include the NTP cookbook by adding:
```ruby
# For Linux systems
if platform_family?('debian', 'rhel')
  node.default['ntp']['servers'] = node['time']['ntp_servers']
  include_recipe 'ntp::default'
end
```

## Attribute Mapping

Our cookbook attributes map to the NTP cookbook as follows:

| enterprise-time attribute | ntp cookbook attribute |
|---------------------------|------------------------|
| `node['time']['ntp_servers']` | `node['ntp']['servers']` |
| `node['time']['ntp_service_enabled']` | Handled by service resources |

## Benefits of NTP Supermarket Cookbook

1. **Community Maintained**: Active maintenance by Sous Chefs
2. **Battle Tested**: 93 versions, widely used in production
3. **Comprehensive Features**:
   - Support for NTP servers, pools, and peers
   - Fine-grained control over NTP behavior (iburst, burst, minpoll, maxpoll)
   - Statistics and monitoring support
   - Leapseconds file management
   - AppArmor integration for Ubuntu
4. **Platform Specific Logic**: Handles platform differences automatically
5. **Windows Support**: Includes Meinberg NTPd client for Windows (though we use W32Time)

## Testing

### Update Policyfile

```bash
cd /Users/bphillip/Documents/CHEF/GIT_REPO/time-cookbook
chef update Policyfile.rb
```

### Test with Kitchen

```bash
# Test with the new recipe
kitchen converge default-ubuntu-2204

# Test with the new recipe on Amazon Linux
kitchen converge default-amazonlinux-2023
```

### Verify NTP Configuration

On Linux systems after convergence:
```bash
# Check NTP service status
systemctl status ntp        # For Ubuntu < 22.04
systemctl status ntpd       # For older RHEL/CentOS
systemctl status chronyd    # For modern RHEL 8+/Amazon Linux 2023

# Check NTP servers configured
cat /etc/ntp.conf           # For classic NTP
cat /etc/chrony.conf        # For chrony

# Verify time synchronization
ntpq -p                     # For classic NTP
chronyc sources             # For chrony
```

## Platform Compatibility

### Full NTP Supermarket Support
- Ubuntu < 22.04
- Debian < 12
- RHEL/CentOS 7
- Amazon Linux 2

### Chrony Fallback (RHEL 8+ limitation)
- RHEL/CentOS 8+
- Amazon Linux 2023+
- Ubuntu 22.04+ (uses chrony by default)

### Windows
- Uses native W32Time (not NTP supermarket cookbook)

## Rollback Plan

If you encounter issues with the NTP supermarket integration:

1. **Revert to original recipe**: Change run list back to `enterprise-time::default`
2. **Remove dependency**: Comment out the ntp dependency in `metadata.rb`
3. **Update Policyfile**: Remove the NTP cookbook line from `Policyfile.rb`
4. **Run chef update**: `chef update Policyfile.rb`

## Next Steps

1. **Test on various platforms** using Test Kitchen
2. **Compare NTP accuracy** between custom implementation and supermarket cookbook
3. **Consider full migration** if supermarket cookbook proves superior
4. **Update CI/CD** to test both recipes
5. **Document attribute override** patterns for advanced NTP configuration

## Advanced NTP Configuration

The NTP supermarket cookbook supports many advanced features:

```ruby
# In Policyfile.rb or role
default['ntp']['servers'] = ['time1.example.com', 'time2.example.com']
default['ntp']['peers'] = ['peer1.example.com', 'peer2.example.com']
default['ntp']['restrictions'] = ['10.0.0.0 mask 255.0.0.0 nomodify notrap']
default['ntp']['sync_clock'] = true  # Force time sync on every run
default['ntp']['sync_hw_clock'] = true  # Sync hardware clock
default['ntp']['server']['use_iburst'] = true  # Fast initial sync
default['ntp']['server']['minpoll'] = 6  # Minimum poll interval (2^6 = 64 seconds)
default['ntp']['server']['maxpoll'] = 10  # Maximum poll interval (2^10 = 1024 seconds)
```

## References

- NTP Supermarket Cookbook: https://supermarket.chef.io/cookbooks/ntp
- Sous Chefs GitHub: https://github.com/sous-chefs/ntp
- NTP.org Documentation: http://support.ntp.org/
- Chrony Documentation: https://chrony.tuxfamily.org/
