# k8s-2025 Naming Conventions

Last updated: 2026-04-01
Status: Initial recommendations

## Goal
Make files, playbooks, AWX templates, and docs easier to find, sort, and understand without needing to remember tribal lore.

## Core Principles
- Prefer **system + intent + object** over vague labels.
- Use one naming pattern per artifact type.
- Keep names predictable enough that search is optional rather than mandatory.
- Avoid overloaded terms like `maintenance` unless they are narrowly defined.

## AWX Job Template Naming

### Current problem
Current AWX names mix several patterns:
- action-first: `Deploy - Clawdbot`, `Patch - Proxmox Cluster`
- system-first: `Proxmox - Configure Node`, `MotionEye - Deploy camera2`
- broad bucket labels: `Maintenance - Deploy PBS Server`, `Ad-hoc - Check Pending Updates`

### Recommended AWX pattern
Use:

`<Domain> - <System/Scope> - <Intent>`

Where:
- **Domain** = Deploy | Configure | Operate | Patch | Recover | Audit | Sync | Workflow
- **System/Scope** = Proxmox | Kubernetes | Clawdbot | Frigate | MotionEye | OctoPrint | TrueNAS | Infrastructure
- **Intent** = specific verb/object

Examples:
- `Deploy - Clawdbot - Base Host`
- `Recover - Clawdbot - Alfred Artifacts`
- `Patch - Kubernetes - Rolling Nodes`
- `Patch - Infrastructure - Automatic Systems`
- `Operate - Proxmox - Join Cluster`
- `Operate - Kubernetes - Check Cluster Health`
- `Sync - AWX - Inventory to Kea`
- `Workflow - Infrastructure - Full Patch`

### Additional AWX rules
- Do not mix singular and plural for the same job family unless scope truly differs.
- Use a consistent canonical system name (`Kubernetes`, not alternating `K8s`/`Kubernetes` in template names).
- Reserve `Workflow - ...` for workflow templates only.
- Reserve `Ad-hoc` only if AWX is truly invoking arbitrary ad-hoc logic; otherwise replace with a real domain.

### Specific inconsistencies found
- schedules reference `Patch - Kubernetes Node`, while template name present is `Patch - Kubernetes Nodes`
- `Maintenance - Deploy PBS Server` is semantically a deploy/configure job, not maintenance
- `Maintenance - Fix keepalived API Health Check` is really an operate/configure job
- `Proxmox - Join Cluster` differs structurally from most action-first names

## Ansible Playbook Naming

### Recommended pattern
Use lowercase kebab-case with system-first naming:

`<system>-<intent>.yml`

Examples:
- `clawdbot-deploy.yml`
- `clawdbot-recover-alfred.yml`
- `kubernetes-check-cluster.yml`
- `kubernetes-patch-node.yml`
- `proxmox-join-cluster.yml`
- `proxmox-configure-node.yml`
- `truenas-upgrade-apps.yml`

### Directory intent should do some work
If playbooks are moved into intent directories, names can shorten slightly, but should still be specific.
For example under `playbooks/operate/`:
- `kubernetes-check-cluster.yml`
- `proxmox-disable-wdmd.yml`

Avoid names that require directory context plus human memory to decode, such as just `restore.yml` or `backup.yml` if the scope is not obvious.

## Script Naming

### Recommended pattern
Use imperative kebab-case:

`<verb>-<object>.sh`
`<verb>-<object>.py`

Examples:
- `backup-configs.sh`
- `restore-configs.sh`
- `sync-awx-inventory.py`
- `sync-kea-opnsense-gui.py` or a more precise equivalent
- `deploy-homeassistant-pxe.sh`

### Script naming rules
- Prefer one canonical spelling for a product/system (`proxmox`, not `proxmenux` unless preserving a historical script name intentionally)
- Prefix migration-only scripts with `migrate-`
- Prefix analysis/audit scripts with `audit-` or `analyze-`
- Prefix synchronization scripts with `sync-`
- Avoid `setup-` when `install-`, `configure-`, or `generate-` would be clearer

### Legacy cleanup candidates noticed today
- `install-proxmenux.sh`
- `cleanup-old-proxmenux.sh`

These likely need either renaming or a clearly documented exception.

## Documentation Naming

### Recommended patterns by doc type
- Guides: `<system>-<topic>-guide.md`
- Quick references: `<system>-quick-reference.md`
- Runbooks: `<system>-<task>-runbook.md`
- Migrations/plans: `<system>-<topic>-migration-plan.md`
- RCA/incidents: `incident-YYYY-MM-DD.HHMM-<system>-<summary>.md`
- Architectural/design records: `<topic>-architecture.md` or ADR-style names if adopted

### Current docs issues observed
- uppercase summary files mixed with regular docs (`ANSIBLE-IAC-SUMMARY.md`, `K8S-ANSIBLE-COMPLETE.md`)
- multiple `README-*` files behave more like guides than READMEs
- RCA names are mostly structured, but some include triple hyphens and mixed summary formatting

### Recommendation for READMEs
Use `README.md` only as an index/entry document for a directory.
Avoid `README-topic.md` at the top level when a normal descriptive filename would be clearer.

## Directory Naming
- use lowercase kebab-case for directories where practical
- reserve generic names like `docs`, `scripts`, `files`, `vars` only when they are conventional and scoped
- prefer intent-driven directory names over historical tool buckets when operator navigation matters more

## Adoption Guidance
- define canonical terms first: `Kubernetes`, `Proxmox`, `TrueNAS`, `AWX`, `Clawdbot`, `Frigate`, `MotionEye`, `OctoPrint`
- normalize AWX names before or alongside path changes
- batch renames by artifact family, not random file-by-file churn
- document exceptions where external systems depend on a legacy name

## Initial Recommendation
For this repo, prioritize AWX template naming and playbook naming first. Those are the operator-facing surfaces most likely to benefit immediately.
