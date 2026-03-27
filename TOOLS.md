# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

### Infrastructure Access

- **OPNsense:** `root@opnsense.lan` (172.16.1.1) — SSH, **read-only** (no changes permitted)
- **vm01.lan:** `aheinen@vm01.lan` (172.16.1.141) — SSH, **read-only** except: may restart Frigate VM 105 (`sudo qm start 105`)
- **dsp01.lan:** `aheinen@dsp01.lan` — camera feed kiosk display. Restart lightdm (`sudo systemctl restart lightdm`) after Frigate recovery.
- **ntfy:** `https://ntfy.heinenshome.com` — alerts topic, polling + streaming

### Services

- **ntfy-alert-listener:** systemd user service on clawdbot.lan
  - Streams `ntfy.heinenshome.com/alerts`, filters flaps (2 min window), alerts via Telegram
  - Auto-restarts Frigate VM 105 on OOM kill (10 min cooldown), then restarts lightdm on dsp01.lan after 30s delay
  - Script: `/home/aheinen/.openclaw/scripts/ntfy-alert-listener.py`

Add whatever helps you do your job. This is your cheat sheet.
