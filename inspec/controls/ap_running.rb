control 'ap-01' do
  impact 1.0
  title 'Access Point is running'
  desc 'hostapd must be active and the br0 bridge must exist and be up'

  describe service('hostapd') do
    it { should be_enabled }
    it { should be_running }
  end

  describe interface('br0') do
    it { should exist }
    it { should be_up }
  end
end

control 'ap-02' do
  impact 0.9
  title 'Bridge has correct IP address'
  desc 'br0 must carry the configured AP subnet gateway IP'

  describe interface('br0') do
    its('ipv4_addresses') { should include '192.168.88.1' }
  end
end

control 'ap-03' do
  impact 0.9
  title 'AP config references wlan0 on the bridge'
  desc 'hostapd must bind the onboard radio into br0'

  describe file('/etc/hostapd/hostapd.conf') do
    it { should exist }
    its('content') { should match(/^interface=wlan0/) }
    its('content') { should match(/^bridge=br0/) }
    its('content') { should match(/^ssid=/) }
    its('content') { should match(/^wpa=2/) }
  end
end
