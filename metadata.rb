name 'enterprise-time'
maintainer 'Progress Software Corporation - SA Team - POC Demo'
maintainer_email 'bryan.phillips@progress.com'
license 'Apache-2.0'
description 'Cross-platform time management cookbook with real W32Time and smart NTP detection'
version '3.1.1'
chef_version '>= 16.0'

# No external dependencies - fully self-contained

# Platform support
supports 'windows', '>= 2012.0'
supports 'ubuntu', '>= 18.04'
supports 'amazon', '>= 2.0'
supports 'centos', '>= 7.0'
supports 'redhat', '>= 7.0'

source_url 'https://github.com/bassslap/time-cookbook'
issues_url 'https://github.com/bassslap/time-cookbook/issues'
