# InSpec test for time-cookbook

describe 'Time and NTP configuration' do
  context 'when on Windows' do
    next unless os.windows?
    
    describe service('w32time') do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end
    
    describe powershell('w32tm /query /status') do
      its('exit_status') { should eq 0 }
    end
    
    describe powershell('Get-TimeZone | Select-Object -ExpandProperty Id') do
      its('stdout.strip') { should_not be_empty }
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
    if service(ntp_service).name == 'chronyd'
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