control 'uplink-01' do
  impact 1.0
  title 'WiFi uplink client is running'
  desc 'wpa_supplicant@wlan1 (AX210) must be active for the campus WiFi connection'

  describe service('wpa_supplicant@wlan1') do
    it { should be_enabled }
    it { should be_running }
  end
end

control 'uplink-02' do
  impact 0.8
  title 'NetworkManager does not manage the router interfaces'
  desc 'wlan0/wlan1/eth0 must be unmanaged so NM does not fight the router stack'

  describe file('/etc/NetworkManager/conf.d/99-travel-router-unmanaged.conf') do
    it { should exist }
    its('content') { should match(/unmanaged-devices=.*wlan0.*wlan1/) }
  end
end

control 'uplink-03' do
  impact 0.9
  title 'Uplink has connectivity'
  desc 'the Pi must be able to reach the internet through the uplink'

  describe command('curl -s --max-time 10 -o /dev/null -w "%{http_code}" https://1.1.1.1') do
    its('stdout') { should match(/^(200|301|302)$/) }
  end
end
