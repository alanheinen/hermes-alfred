# Automated Network Operations Plan

## Goal
Daily automated health monitoring, log analysis, and proactive maintenance for your homelab infrastructure.

## Proposed Automation Layers

### 1. Daily Health Report (Morning Brief)
**Time:** 7:00 AM America/Chicago daily
**Components:**
- Cluster status (K8s nodes, pod health, resource usage)
- Storage health (TrueNAS, iSCSI, PV/PVC status)
- Network status (connectivity, DNS, ingress)
- Backup validation (last run timestamps, success/fail)
- Certificate expiry warnings (< 30 days)
- Security alerts (failed SSH attempts, unusual traffic)

**What I need from you:**
- Access credentials for:
  - Proxmox API (user/token or API key)
  - K8s cluster (kubeconfig file location)
  - TrueNAS API (if available)
  - AWX/Ansible logs
- Preferred report format (brief summary vs detailed)
- Alert thresholds (disk usage %, pod restart counts, etc.)

### 2. Log Analysis & Anomaly Detection
**Frequency:** Continuous + daily digest
**Targets:**
- Proxmox host logs
- K8s pod logs (failures, errors, crashes)
- NGINX Ingress logs (4xx/5xx spikes)
- System logs (auth, kernel, syslog)

**What I need from you:**
- Log aggregation setup (do you have Loki/ELK, or should I SSH and grep?)
- SSH access to key nodes (or log forwarding to a central location)
- Known "noisy" services to filter out
- Which errors are "normal" vs concerning

### 3. Proactive Maintenance
**Tasks:**
- Weekly disk space monitoring (alert at 80%, critical at 90%)
- Monthly security patch review (scan for CVEs, stage updates)
- Quarterly certificate renewal checks
- Backup integrity tests (random restore validation)
- DNS/external connectivity health checks

**What I need from you:**
- Maintenance windows (when can I safely reboot/upgrade things?)
- Risk tolerance (auto-patch everything vs manual approval?)
- Backup restore test schedule (monthly? quarterly?)
- Critical vs non-critical services (which can tolerate downtime?)

### 4. Self-Healing Automation
**Scenarios:**
- Pod crash loops → investigate + restart + alert
- Disk space critical → clean temp files / rotate logs
- Service down → attempt restart, escalate if fails
- Certificate near expiry → trigger renewal early

**What I need from you:**
- Which services can I auto-restart without asking?
- Cleanup policies (what's safe to delete?)
- Escalation contacts (SMS, call, just Telegram?)

## Implementation Plan
**Week 1:** Basic daily health report (cluster + storage + backups)
**Week 2:** Log analysis pipeline setup
**Week 3:** Proactive maintenance automation
**Week 4:** Self-healing rules (start conservative, expand over time)

## Tech Stack
- Ansible playbooks for checks and remediation
- Python scripts for log parsing and API queries
- Cron jobs for scheduling
- Telegram for alerts and daily reports

## Next Steps
1. Provide access credentials (store securely, I'll guide you)
2. Define your comfort level with auto-remediation
3. I'll build a prototype daily report this weekend
4. Iterate based on what's useful vs noisy
