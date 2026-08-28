control 'routing-01' do
  impact 1.0
  title 'IPv4 forwarding is enabled'

  describe kernel_parameter('net.ipv4.ip_forward') do
    its('value') { should eq 1 }
  end
end

control 'routing-02' do
  impact 1.0
  title 'nftables service is running'

  describe service('nftables') do
    it { should be_enabled }
    it { should be_running }
  end
end

control 'routing-03' do
  impact 1.0
  title 'NAT masquerade rule exists for wlan1'
  desc 'nftables must have a postrouting masquerade on the uplink'

  describe command('nft list ruleset') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/oifname "wlan1"/) }
    its('stdout') { should match(/masquerade/) }
  end
end

control 'routing-04' do
  impact 0.8
  title 'Forward chain allows br0 -> wlan1'

  describe command('nft list ruleset') do
    its('stdout') { should match(/iifname "br0".*oifname "wlan1"/) }
  end
end
