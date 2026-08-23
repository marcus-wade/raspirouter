# raspirouter

Headless Raspberry Pi 5 **campus WiFi extender**: joins a weak campus WiFi
network with a high-gain WiFi 6 card, then shares it over gigabit ethernet and
a private access point — with phone-based setup via a built-in web app.

```
[campus WiFi]                          (weak signal spot)
      ↑  wlan1 — Intel AX210 on PCIe M.2 E-key hat (station/uplink)
[Raspberry Pi 5]  ← NAT router
      ↓  br0 = { eth0 wired port + wlan0 onboard radio (AP "RaspiRouter") }
[computer]  [phone]  → 192.168.88.1 web setup app
```

Built for a Wingate University dorm: `WingateResnet` joins without a WiFi
password but requires a **captive-portal web login** per device. Because the
Pi NATs everything behind its own WiFi MAC, one portal login from *any*
device behind the Pi shares the session for all of them. If the session ever
expires, just browse any HTTP site from the computer or phone and the campus
login page pops up again.

## Hardware

- Raspberry Pi 5 (+ official PSU)
- M.2 E-key HAT with **Intel AX210** (WiFi 6), antennas attached
- Raspberry Pi OS **Bookworm Lite 64-bit**
- Ethernet cable to the device you want online

> The AX210 needs external PCIe enabled. Add `dtparam=pciex1` (and
> `dtparam=pciex1_gen=2` if the link is flaky through the ribbon) under
> `[all]` in `/boot/firmware/config.txt`. Verify with `lspci` — you should
> see a "Network controller: Intel AX210".

## Flash & first boot

Use Raspberry Pi Imager → OS customization:
- hostname `raspirouter`, SSH enabled, user `g1tech`
- your **home** WiFi credentials so it reaches the internet at home
- timezone `America/New_York`

Boot, find its IP on your home network, then:

```bash
ssh g1tech@<ip>            # install your key or keep password auth for now
sudo apt update && sudo apt install -y ansible   # run provisioning locally...
# ...or run ansible from your laptop against the Pi (see below)
```

## Provisioning

```bash
cd ansible
cp config.example.yml config.yml     # set ap_password etc. (gitignored)
$EDITOR config.yml
ansible-playbook playbook.yml -e @config.yml
```

From your laptop instead of on-Pi? Point `ansible_host` in config.yml at the
Pi's IP and run the same command with `-u g1tech`.

Paranoid about losing the Pi mid-provisioning? Arm the deadman switch:

```bash
ansible-playbook playbook.yml -e @config.yml -e deadman_rollback=true
# keep alive while validating:  watch -n 60 ssh g1tech@<ip> sudo travel-router-keepalive
# happy? make permanent:        ssh g1tech@<ip> sudo travel-router-commit
```

## Moving into the dorm

1. Plug the Pi in near the strongest campus signal (window/outside wall).
2. Connect the computer to the Pi's LAN port.
3. On the phone: join **RaspiRouter** (password from config.yml), open
   `http://192.168.88.1`.
4. Tap **Scan networks**, pick `WingateResnet`, connect. The Pi reboots.
5. From the computer, open any website → Wingate's login page appears → sign
   in once. Every device behind the Pi now shares the connection.

Changing networks later = repeat steps 3–4 from any connected device.

## CLI cheatsheet (on the Pi)

```bash
travel-router status       # uplink SSID/IP, internet, AP clients
travel-router reconnect    # bounce the uplink association
```

## Verification (InSpec)

```bash
inspec exec inspec/ -t ssh://g1tech@<pi-ip> -i ~/.ssh/rpi_key --sudo
```

## Layout notes

- `wlan0` (onboard) = AP only; fixed channel (`ap_channel`/`ap_hw_mode`)
- `wlan1` (AX210) = station uplink only; band selectable 2.4/5/auto
- `eth0` + `wlan0` are bridged as `br0` (192.168.88.1/24, dnsmasq DHCP)
- NetworkManager is uninstalled from routing duty: wlan0/wlan1/eth0 unmanaged;
  a dormant fallback profile lets NM restore connectivity after a rollback
- Watchdog repairs br0/hostapd/dnsmasq every minute (start-only, never restarts
  a healthy hostapd)
- nftables: single permanent ruleset, masquerade out `wlan1`

Based on [rpagliuca/rpi5-hotel-travel-router](https://github.com/rpagliuca/rpi5-hotel-travel-router),
reworked for dual-radio hardware and the Wingate ResNet captive-portal flow.
