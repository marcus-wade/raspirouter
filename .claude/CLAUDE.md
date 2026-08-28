# Project change log (maintained by shipit)

## Recent Changes

### feat: add WPA2-Enterprise uplink and priority fallback networks - 2026-08-23
- Branch: `minor/1-wingate-resnet-extender`
- PR: https://github.com/marcus-wade/raspirouter/pull/2
- Summary: uplink.conf gains IDENTITY (WPA2-Enterprise PEAP/MSCHAPv2 for
  WU-Users) and FALLBACKn_* alternative networks; the orchestrator emits
  prioritized wpa_supplicant blocks so the Pi auto-picks the best network in
  range. Webapp scan flags enterprise networks and collects a username.
