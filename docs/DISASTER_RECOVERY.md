# Alfred / OpenClaw Disaster Recovery

This is the first-pass resurrection kit for rebuilding Alfred on a fresh `clawdbot` host without committing live secrets to git like a raccoon with root access.

## What this kit restores automatically

Tracked, git-safe artifacts now exist for:

- redacted OpenClaw config: `backups/openclaw.json`
- exported OpenClaw cron definitions: `backups/cron-jobs.json`
- restore helper script: `scripts/restore_openclaw_from_backup.py`
- AWX/Ansible recovery path in `k8s-2025/ansible/playbooks/clawdbot-resurrection.yml`
- AWX-deployable recovery seed files in `k8s-2025/alfred/recovery/`

That gets a rebuilt host most of the way there:

- OpenClaw installed
- recovery helper files staged on the host
- redacted config seeded into `~/.openclaw/openclaw.json`
- cron job manifest seeded into `~/.openclaw/cron/jobs.json`
- manual-secret templates copied into place

What it **does not** do:

- restore live tokens or API keys
- restore OpenAI/Anthropic auth state stored outside the redacted backup
- recreate Telegram pairing state automatically
- recreate arbitrary local runtime history (`memory/main.sqlite`, delivery queue, etc.)

## AWX recovery flow

Use the new AWX job template / playbook:

- playbook: `ansible/playbooks/clawdbot-resurrection.yml`
- host limit: `clawdbot.lan`

Recommended order:

1. Rebuild/provision the VM normally.
2. Run the standard `Deploy - Clawdbot (OpenClaw AI Assistant)` job if the host is truly blank.
3. Run `Recover - Clawdbot / Alfred` to seed the redacted recovery kit.
4. SSH in and complete the manual secret/key steps below.
5. Restart OpenClaw services and validate.

## Manual steps after automation

### 1) Confirm seed files landed

On the rebuilt host:

```bash
ls -la ~/.openclaw/openclaw.json ~/.openclaw/cron/jobs.json ~/alfred-resurrection
```

### 2) Re-provide OpenClaw secrets

Edit `~/.openclaw/openclaw.json` and replace the redacted placeholders for:

- `channels.telegram.botToken`
- `gateway.auth.token`

You can use the staged example file as a checklist:

```bash
cat ~/alfred-resurrection/examples/openclaw-manual-secrets.env.example
```

### 3) Re-provide provider auth

The redacted backup preserves auth *shape*, not live credentials.
Recreate whichever auth modes Alfred should use now.

Current expected posture:

- primary: `openai-codex` OAuth / subscription-backed auth
- fallback: `openai-codex/gpt-5.2` only

Likely command to run locally as `aheinen`:

```bash
openclaw auth login openai-codex
```

If CLI prompts or command names drift, use:

```bash
openclaw auth --help
openclaw models
```

### 4) Recreate Telegram / external env-backed secrets

If restoring `ntfy-alert-listener` or other external services, recreate their env files from templates rather than editing tracked unit files:

```bash
sudo install -o root -g root -m 600 \
  ~/alfred-resurrection/examples/openclaw-manual-secrets.env.example \
  /etc/default/ntfy-alert-listener
```

Then replace placeholders before restarting the service.

### 5) Reconnect Telegram / gateway behavior

Validate:

- Telegram bot token works
- allowed chats/pairing behave as expected
- gateway token is accepted by clients/nodes

Depending on what was lost, you may also need to re-pair devices/nodes.

### 6) Restart services

OpenClaw on this host currently uses a user-level gateway service, so after restoring config/auth:

```bash
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway
systemctl --user status openclaw-gateway --no-pager
```

If you also use the Ansible-installed system service:

```bash
sudo systemctl restart openclaw
sudo systemctl status openclaw --no-pager
```

## Local/manual restore without AWX

If the host already has the repo checkout and Python 3, you can seed the redacted files directly:

```bash
python3 /home/aheinen/.openclaw/workspace/scripts/restore_openclaw_from_backup.py \
  --config-src /home/aheinen/.openclaw/workspace/backups/openclaw.json \
  --config-dest /home/aheinen/.openclaw/openclaw.json \
  --cron-src /home/aheinen/.openclaw/workspace/backups/cron-jobs.json \
  --cron-dest /home/aheinen/.openclaw/cron/jobs.json \
  --force
```

That restores only the **redacted** baseline. You still need to reinsert secrets and auth.

## Validation checklist

Run these after the manual steps are complete:

```bash
openclaw status
openclaw models
openclaw gateway status
systemctl --user status openclaw-gateway --no-pager
journalctl --user -u openclaw-gateway -n 100 --no-pager
```

Also verify:

- Telegram delivery works end to end
- daily cron jobs appear in `~/.openclaw/cron/jobs.json`
- `~/.openclaw/logs/cron-jobs.log` starts receiving entries again
- workspace backup job can refresh `backups/openclaw.json`

## Keeping the resurrection kit current

After meaningful OpenClaw config or cron changes:

1. Refresh the redacted config backup:

```bash
python3 scripts/redact_openclaw_config.py \
  /home/aheinen/.openclaw/openclaw.json \
  /home/aheinen/.openclaw/workspace/backups/openclaw.json
```

2. Refresh the tracked cron export:

```bash
cp /home/aheinen/.openclaw/cron/jobs.json /home/aheinen/.openclaw/workspace/backups/cron-jobs.json
```

3. Mirror the safe seed artifacts into `k8s-2025/alfred/recovery/` so AWX has the latest resurrection payload.

Because apparently future-Al also deserves nice things.
