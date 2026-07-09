#
# Cookbook:: enterprise-time
# Recipe:: linux
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Linux-specific NTP and timezone configuration
# Supports: Ubuntu 22.04+, Amazon Linux 2023+, RHEL 8+
#
# ARCHITECTURE:
# - NTP Configuration: Chrony Supermarket Cookbook (community maintained)
# - Timezone Configuration: Chef Built-in Resource (native to Chef Infra Client)

# ============================================================================
# NTP CONFIGURATION - Using Chrony Supermarket Cookbook
# ============================================================================
# Source: https://supermarket.chef.io/cookbooks/chrony
# Maintained by: Sous Chefs community
# This handles chrony service installation, configuration, and management
# ============================================================================

Chef::Log.info("Configuring chrony NTP service for #{node['platform']} #{node['platform_version']}")

chrony_servers = {}

node['time']['ntp_servers'].each do |server|
  chrony_servers[server] = 'iburst'
end

chrony_config 'default' do
  servers chrony_servers
end

Chef::Log.info("✅ Configured chrony with NTP servers: #{node['time']['ntp_servers'].join(', ')}")

# ============================================================================
# TIMEZONE CONFIGURATION - Using Chef Built-in Resource
# ============================================================================
# Chef Infra Client provides a native 'timezone' resource that handles
# timezone configuration across all platforms (Windows, Linux, macOS)
# Documentation: https://docs.chef.io/resources/timezone/
# ============================================================================

# Set timezone directly - override in wrapper cookbook or via node.override if needed
timezone_to_set = 'America/New_York'

Chef::Log.info("Setting Linux timezone to: #{timezone_to_set}")

# *** CHEF BUILT-IN RESOURCE ***
# Using Chef Infra Client's native timezone resource (no external dependency)
timezone timezone_to_set do
  action :set
end
# *** END CHEF BUILT-IN RESOURCE ***

Chef::Log.info("✅ Linux timezone configuration completed: #{timezone_to_set}")
