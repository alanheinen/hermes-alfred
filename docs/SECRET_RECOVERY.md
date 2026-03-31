# Secret Recovery & Redacted Config Backups

This workspace stores a **redacted** backup of OpenClaw config at:

- `backups/openclaw.json`

That file is intentionally safe to commit because live secrets are removed.

## Secrets intentionally excluded from git-backed config backups

Currently redacted from `backups/openclaw.json`:

- `channels.telegram.botToken`
- `gateway.auth.token`

Tracked repo files should also avoid embedding secrets directly.

## Recovery after loss

If the host is rebuilt or secrets are lost, restore in this order.

### 1) Restore the non-secret config

Copy the redacted backup into place as a starting point:

```bash
cp /home/aheinen/.openclaw/workspace/backups/openclaw.json /home/aheinen/.openclaw/openclaw.json
```

This restores the structure and non-secret settings, but **not** the live secrets.

### 2) Recreate Telegram bot token

Needed for:

- OpenClaw Telegram channel config (`channels.telegram.botToken`)
- any external services that send Telegram alerts

How to recreate:

1. Open Telegram and message `@BotFather`
2. Use `/mybots` or `/newbot`
3. Create/reissue the bot token
4. Update the runtime config with the new token

Where it must be reinserted:

- `~/.openclaw/openclaw.json` → `channels.telegram.botToken`
- any external env file used by services such as `ntfy-alert-listener`

### 3) Recreate gateway auth token

Needed for:

- authenticated local/gateway access to OpenClaw

How to recreate:

- generate a new high-entropy token, for example:

```bash
python3 - <<'PY'
import secrets
print(secrets.token_hex(24))
PY
```

Then place it into:

- `~/.openclaw/openclaw.json` → `gateway.auth.token`

### 4) Recreate external service env files

Some external services should use **env files** instead of checked-in unit files.

Example for `ntfy-alert-listener`:

Suggested tracked template:

- `k8s-2025/alfred/ntfy-alert-listener.env.example`

Suggested deployed file:

- `/etc/default/ntfy-alert-listener`

Example contents:

```bash
TELEGRAM_BOT_TOKEN=<your-telegram-bot-token>
TELEGRAM_CHAT_ID=<your-chat-id>
```

Recommended permissions:

```bash
sudo chown root:root /etc/default/ntfy-alert-listener
sudo chmod 600 /etc/default/ntfy-alert-listener
```

If the unit is system-level, reload/restart after changes:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ntfy-alert-listener
```

If it is a user service instead:

```bash
systemctl --user daemon-reload
systemctl --user restart ntfy-alert-listener
```

### 5) Validate OpenClaw after secret restoration

```bash
openclaw status
openclaw security audit
```

Also verify:

- Telegram bot responds
- gateway clients can connect
- daily cron jobs still run

## Redacted backup workflow

To refresh the git-safe backup from the live config:

```bash
python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py \
  /home/aheinen/.openclaw/openclaw.json \
  /home/aheinen/.openclaw/workspace/backups/openclaw.json
```

## Repo hygiene rules

- Never commit live tokens into tracked files
- Prefer placeholders in docs
- Prefer `EnvironmentFile=` over inline `Environment=` secrets in tracked unit files
- Treat runtime secret stores and local auth files as sensitive, even if excluded from git
