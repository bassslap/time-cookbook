# InSpec test for enterprise-time cookbook

describe 'Time and NTP configuration' do
  context 'when on Windows' do
    next unless os.windows?

    describe service('w32time') do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end

    # Test W32Time status and functionality
    describe powershell('w32tm /query /status') do
      its('exit_status') { should eq 0 }
      its('stdout') { should_not be_empty }
    end

    # Test timezone configuration
    describe powershell('Get-TimeZone | Select-Object -ExpandProperty Id') do
      its('stdout.strip') { should_not be_empty }
    end

    # Test that timezone is set to Eastern Standard Time (EST)
    describe powershell('Get-TimeZone | Select-Object -ExpandProperty Id') do
      its('stdout.strip') { should eq 'Eastern Standard Time' }
    end

    # Test critical registry settings
    describe registry_key('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters') do
      it { should exist }
      it { should have_property('NoModifySystemTime') }
      its('NoModifySystemTime') { should eq 0 }
    end

    # Test W32Time configuration registry settings
    describe registry_key('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config') do
      it { should exist }
      it { should have_property('MaxPosPhaseCorrection') }
      it { should have_property('MaxNegPhaseCorrection') }
      it { should have_property('AnnounceFlags') }
      its('MaxPosPhaseCorrection') { should eq 172800 }
      its('MaxNegPhaseCorrection') { should eq 172800 }
      its('AnnounceFlags') { should eq 5 }
    end

    # Test NTP server configuration
    describe powershell('w32tm /query /configuration') do
      its('exit_status') { should eq 0 }
      its('stdout') { should match(/pool\.ntp\.org/) }
    end

    # Test time synchronization capability
    describe powershell('w32tm /query /peers') do
      its('exit_status') { should eq 0 }
      its('stdout') { should_not be_empty }
    end
  end

  context 'when on Linux' do
    next if os.windows?

    # Check if chrony or ntp is running
    ntp_service = if file('/usr/bin/chronyd').exist? || file('/usr/sbin/chronyd').exist?
                    'chronyd'
                  elsif file('/usr/sbin/ntpd').exist?
                    'ntpd'
                  else
                    'ntp'
                  end

    describe service(ntp_service) do
      it { should be_enabled }
      it { should be_running }
    end

    # Check timezone configuration
    if file('/usr/bin/timedatectl').exist?
      describe command('timedatectl status') do
        its('exit_status') { should eq 0 }
        its('stdout') { should match(/Time zone:/) }
      end
    else
      describe file('/etc/timezone') do
        it { should exist }
        it { should be_file }
      end

      describe file('/etc/localtime') do
        it { should exist }
        it { should be_symlink }
      end
    end

    # Check NTP configuration files
    if ntp_service == 'chronyd'
      describe file('/etc/chrony.conf') do
        it { should exist }
        it { should be_file }
        its('content') { should match(/server.*pool\.ntp\.org/) }
      end
    else
      describe file('/etc/ntp.conf') do
        it { should exist }
        it { should be_file }
        its('content') { should match(/server.*pool\.ntp\.org/) }
      end
    end
  end
end
