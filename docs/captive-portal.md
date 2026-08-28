# Campus captive portal (Wingate ResNet) flow

Wingate's residence network works like most hotel-style networks: the SSID
(`WingateResnet`) joins with no WiFi password, but each *device* must complete
a web login before traffic is allowed out.

## How raspirouter handles it

The Pi associates to `WingateResnet` on `wlan1` and NATs all LAN devices
(bridge `br0`: wired port + AP) behind the Pi's wireless MAC. Consequences:

- The campus network sees ONE device: the Pi. Once the portal session for the
  Pi's MAC is active, every device behind it has internet.
- Any device behind the Pi can (re)do the login: browse any HTTP site and the
  campus redirect appears. Windows/Android/iOS captive-portal detection pops
  it automatically when the session is missing.
- There are no modes to switch: forwarding is always open, so the portal is
  always reachable.

## Session expiry

ResNet sessions time out periodically (days). Symptom: devices report
"connected, no internet". Fix: open any non-HTTPS site from the computer,
log in again. Nothing on the Pi needs to change.

## First-time setup from the phone (no computer needed)

1. Join the `RaspiRouter` AP.
2. Open http://192.168.88.1 → Scan → select `WingateResnet` → Connect.
3. After the reboot, join `RaspiRouter` again and browse to any HTTP site;
   the Wingate login page appears — sign in with the student account.
4. The computer plugged into the LAN port is already online.

## Troubleshooting

| Symptom | Check |
|---|---|
| Webapp shows uplink disconnected | Signal too weak — move the Pi closer to a window/AP; check antennas |
| Uplink associated, no internet | Portal login pending — browse an HTTP site from a client |
| Login page never appears | Try `http://neverssl.com` explicitly; some portals need plain HTTP |
| Still blocked after login | Campus may require MAC registration for the Pi — register `wlan1`'s MAC shown on the status card / `ip link show wlan1` |
