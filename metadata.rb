name 'enterprise-time'
maintainer 'Your Organization'
maintainer_email 'devops@yourorganization.com'
license 'Apache-2.0'
description 'Production-ready time synchronization and timezone management for Windows and Linux using proven Chef Supermarket cookbooks'
version '2.0.0'
chef_version '>= 16.0'

# Production dependencies on proven Supermarket cookbooks
depends 'ntp', '~> 3.7.0' # Most popular NTP cookbook (500k+ downloads)
depends 'timezone', '~> 0.2.0'      # Dedicated timezone management
depends 'windows', '~> 9.1.0'       # Windows platform resources

# Platform support - tested and validated
supports 'windows', '>= 2012.0'
supports 'ubuntu', '>= 18.04'
supports 'debian', '>= 9.0'
supports 'redhat', '>= 7.0'
supports 'centos', '>= 7.0'
supports 'fedora', '>= 30.0'
supports 'amazon', '>= 2.0'
supports 'suse', '>= 12.0'

source_url 'https://github.com/bassslap/time-cookbook'
issues_url 'https://github.com/bassslap/time-cookbook/issues'

# Cookbook attributes
