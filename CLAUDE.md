# CLAUDE.md

Guidance for working in this repository.

## Project Overview

**raspirouter** — headless Raspberry Pi 5 campus WiFi extender. Joins an upstream
WiFi network (Wingate University `WingateResnet`, captive-portal web login) using
an Intel AX210 WiFi 6 card on a Waveshare PCIe-to-M.2-E-Key HAT+, then shares the
connection over the gigabit ethernet port and a private AP (`RaspiRouter`,
192.168.88.1). Phone-based setup via built-in Flask webapp.

Forked/adapted from [rpagliuca/rpi5-hotel-travel-router](https://github.com/rpagliuca/rpi5-hotel-travel-router).

## Commands

```bash
# Syntax check (venv created during development; recreate as needed)
python3 -m venv .venv && ./.venv/bin/pip install ansible-core
./.venv/bin/ansible-playbook --syntax-check -i ansible/inventory/hosts.yml ansible/playbook.yml

# Provision (from laptop; see ansible/config.example.yml -> config.yml, gitignored)
cd ansible && ansible-playbook playbook.yml -e @config.yml -b

# Provision ON the Pi (local connection survives mid-apply interface handover)
printf 'rpi5:\n  hosts:\n    rpi5:\n      ansible_connection: local\n' > /tmp/local-inv.yml
sudo ./venv/bin/ansible-playbook -i /tmp/local-inv.yml playbook.yml -e @config.yml

# Verify (InSpec)
inspec exec inspec/ -t ssh://g1tech@<pi-ip> -i ~/.ssh/rpi_key --sudo
```

No test suite beyond InSpec controls; validate by applying to hardware.

## Architecture

```
[campus WiFi]
     ↑ wlan1  Intel AX210 (M.2 E-key HAT+), pure STA uplink, wpa_supplicant
[Raspberry Pi 5]  NAT router, nftables masquerade out wlan1
     ↓ br0 = { eth0 wired + wlan0 onboard AP }   192.168.88.1/24
[computer] [phone]  dnsmasq DHCP/DNS, Flask webapp :80
```

Two PHYSICAL radios — no virtual interfaces, no channel pinning. The AP comes up
independently of the uplink state.

### Ansible roles (apply order matters)

1. `rollback-guard` — installs rollback/deadman CLIs FIRST; opt-in auto-revert safety net
2. `base` — packages (incl. firmware-iwlwifi), IP forwarding, SSH hardening, timezone
3. `wifi-client` — takes wlan0/wlan1/eth0 away from NetworkManager; seeds
   `/var/lib/travel-router/uplink.conf` (source of truth); uplink orchestrator service
4. `access-point` — hostapd on wlan0 bridged into br0; systemd-networkd br0/eth0 configs;
   dnsmasq LAN DHCP/DNS; ap-watchdog timer (start-only repairs)
5. `routing` — single permanent nftables ruleset (LAN→wlan1 NAT), `travel-router` CLI
6. `webapp` — Flask app listening only on the bridge IP; scan/select SSID → writes
   uplink.conf → reboots

### Key runtime facts

- `/var/lib/travel-router/uplink.conf`: KEY=VALUE source of truth for the uplink
  (SSID/PASSWORD/OPEN/BAND). Webapp owns it after first provisioning.
- Campus captive portal needs NO special mode: NAT'd devices can always reach it;
  any HTTP browse triggers the login page. One login shares the session for all
  devices behind the Pi's wireless MAC.
- Rollback returns all NICs to NetworkManager using the dormant
  `uplink-fallback.nmconnection` profile.
- Hardware prerequisite: `dtparam=pciex1` in `/boot/firmware/config.txt`
  (AX210 must appear in `lspci`; FFC ribbon orientation is the classic failure).

## Conventions

- Conventional commits `<type>: <description> #<issue>`; PRs only, never push main.
- Secrets live ONLY in `ansible/config.yml` (gitignored).
- Variable names keep upstream semantics: `hotel_*` = the upstream/campus network,
  `ap_*` = our private side. Services/paths keep `travel-router*` names.
- wpa_supplicant generation accepts both quoted passphrases and 64-hex raw PSKs.
- English UI copy in the webapp; code comments explain *why*, referencing constraints.
