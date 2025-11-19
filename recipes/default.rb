#
# Cookbook:: enterprise-time
# Recipe:: default
#
# Copyright:: 2025, Your Organization, All Rights Reserved.
#
# Cross-platform time management with native implementations
#
# COOKBOOK ARCHITECTURE:
# =====================
# LINUX:
#   - NTP: Chrony Supermarket Cookbook (community cookbook)
#   - Timezone: Chef Built-in Resource (native to Chef Infra Client)
#
# WINDOWS:
#   - NTP: Native W32Time commands (no external dependencies)
#   - Timezone: Chef Built-in Resource (native to Chef Infra Client)
#
# EXTERNAL DEPENDENCIES:
#   - chrony cookbook (~> 1.2.6) from Chef Supermarket
#
# CHEF BUILT-IN RESOURCES USED:
#   - timezone resource (cross-platform)
#   - windows_service resource
#   - registry_key resource

Chef::Log.info("Starting enterprise-time cookbook on #{node['platform']} #{node['platform_version']}")

# Include platform-specific recipes
if platform_family?('windows')
  include_recipe 'enterprise-time::windows'
else
  include_recipe 'enterprise-time::linux'
end

# Final verification
log 'cookbook_completion' do
  message "Enterprise-time cookbook completed successfully on #{node['platform']} #{node['platform_version']}"
  level :info
end

Chef::Log.info("✅ Enterprise-time configuration completed successfully with timezone: #{node['time']['timezone']}")

# Final verification
log 'cookbook_completion' do
  message "Enterprise-time cookbook completed successfully on #{node['platform']} #{node['platform_version']}"
  level :info
end

Chef::Log.info("✅ Enterprise-time configuration completed successfully with timezone: #{node['time']['timezone']}")
