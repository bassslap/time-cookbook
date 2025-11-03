# Changelog

All notable changes to this cookbook will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-03

### Added
- Initial release of time-cookbook
- Cross-platform support for Windows and Linux
- Timezone configuration for all supported platforms
- NTP service management with multiple implementation support:
  - Windows W32Time service configuration
  - Linux chrony service (modern, recommended for RHEL 8+)
  - Linux ntpd service (traditional, compatible with older systems)
- Intelligent service selection based on platform and version
- Comprehensive attribute system for customization
- Security-focused NTP configurations with proper access controls
- Template-based configuration management
- Integration tests using InSpec
- Test Kitchen configuration for multiple platforms
- Chef Automate deployment documentation
- Example Policyfile for Chef Automate integration

### Platform Support
- Windows Server (all supported versions)
- Ubuntu 16.04+
- Debian 8+
- RHEL/CentOS 6+
- Fedora (recent versions)
- Amazon Linux 1 & 2
- SUSE Linux Enterprise

### Features
- Automatic detection of systemd vs legacy init systems
- Fallback mechanisms for older Linux distributions
- Conflict prevention between NTP services (chrony vs ntpd)
- PowerShell-based Windows configuration with error handling
- Configurable NTP server pools with regional defaults
- Timezone validation and proper linking on Linux systems
- Service management with proper startup configuration

### Testing
- InSpec integration tests covering all platforms
- Validation of service status, configuration files, and functionality
- Test Kitchen support for Ubuntu, CentOS, and Windows Server
- Multiple test suites for different configuration scenarios

### Documentation
- Comprehensive README with usage examples
- Platform-specific configuration guidance
- Troubleshooting guide
- Chef Automate deployment instructions
- Attribute reference documentation

## [Unreleased]

### Planned
- Support for additional Linux distributions
- Enhanced logging and monitoring integration
- Custom NTP pool configuration templates
- Advanced security hardening options