# k8s-2025 Reorganization Assessment

Last updated: 2026-04-03
Status: Planning baseline updated after execution review

## Purpose
Assess the current repository layout, identify mixed concerns and discoverability issues, and capture evidence that will drive a proposal-ready reorganization plan.

## Current Repository Shape (high level)

### Root-level emphasis today
The repository root currently mixes:
- infrastructure provisioning (`main.tf`, `terraform-*.tf`, `variables.tf`, `providers.tf`)
- operator entry docs (`README.md`, `QUICKSTART.md`, `ANSIBLE-QUICKSTART.md`, `AWX-READY-GUIDE.md`, `BACKUP.md`, `REBUILD-FROM-SCRATCH.md`)
- automation trees (`ansible/`, `scripts/`)
- cluster/runtime config (`applications/`, `cluster-config/`, `networking/`, `storage/`, `cloud-init-templates/`)
- operational records (`docs/`, `audit-logs/`)
- service-specific recovery artifacts (`alfred/recovery/`)

### Directory/file size signals
- `ansible/` is the largest automation tree (~178 files)
- `docs/` is also large (~87 files) and includes a mix of guides, migration plans, quick references, completion summaries, and incident/RCA files
- infra/runtime content is split across several top-level directories instead of a single coherent deployment/configuration hierarchy

## Key Findings

### 1. Root directory is overloaded
The root currently serves as:
- repo landing page
- Terraform working directory
- docs hub
- runbook shelf
- operations archive

That makes first-time orientation harder than it needs to be.

### 2. Deployment, operations, and recovery are interleaved
Examples:
- `alfred/recovery/` contains recovery artifacts, while broader recovery guidance lives at root in `REBUILD-FROM-SCRATCH.md` and backup guidance lives in `BACKUP.md`
- operational playbooks live under `ansible/playbooks/maintenance/`, but operational shell/python scripts live under `scripts/`
- incident records live under `docs/rca-*`, mixed beside setup guides and quick references

### 3. Documentation has mixed lifecycles and audiences
`docs/` currently combines:
- setup/deployment guides (`awx-setup.md`, `frigate-deployment-guide.md`)
- reference/quick reference docs (`pbs-quick-reference.md`)
- design/history/summaries (`ANSIBLE-IAC-SUMMARY.md`, `K8S-ANSIBLE-COMPLETE.md`)
- incident records (`rca-*`, outage notes)
- migration plans (`opnsense-kea-migration-plan.md`)

These are valid documents, but they do not belong in one flat bucket forever.

### 4. Ansible playbook organization is only partially structured
Current playbooks use a hybrid layout:
- top-level playbooks by domain or host (`clawdbot.yml`, `frigate.yml`, `proxmox.yml`, `pbs.yml`)
- a `maintenance/` subdirectory for ops/recovery/troubleshooting tasks

This is better than total chaos, but still mixes deployment intent and operational intent in the same namespace and naming style.

### 5. AWX job template naming is inconsistent in granularity
Observed patterns include:
- `Deploy - <thing>`
- `Recover - <thing>`
- `Patch - <scope>`
- `Maintenance - <action>`
- `OctoPrint - <verb>`
- `MotionEye - <verb>`
- `Ad-hoc - <action>`
- `Proxmox - <action>`
- `Workflow - <name>`

Issues:
- prefix sometimes indicates intent (`Deploy`, `Recover`, `Patch`, `Maintenance`)
- prefix sometimes indicates platform/app (`Proxmox`, `OctoPrint`, `MotionEye`, `TrueNAS`)
- singular/plural drift (`Patch - Kubernetes Nodes` vs schedules referencing `Patch - Kubernetes Node`)
- some “maintenance” jobs are actually deployment/configuration jobs (`Maintenance - Deploy PBS Server`)

### 6. Naming conventions across scripts/playbooks/docs are uneven
Examples of style drift:
- playbooks: both domain names (`proxmox.yml`) and action names (`check-updates.yml`)
- scripts: mixture of imperative verbs, setup verbs, sync verbs, and legacy names (`install-proxmenux.sh`, `cleanup-old-proxmenux.sh`)
- docs: uppercase summary files, `README-*`, `rca-*`, and plain descriptive slugs all coexist

### 7. Overlap exists between declarative app config and GitOps config
Applications are represented in at least two places:
- `applications/` holds manifests/kustomize/service definitions
- `cluster-config/argocd-apps/` holds ArgoCD application definitions referencing app deployment sources

This is normal in principle, but the repo structure does not make the relationship obvious.

## Specific Pain Points Collected This Run
- Root has too many “important entry documents” competing for attention.
- Recovery content is scattered across root docs, Ansible maintenance playbooks, and `alfred/recovery/`.
- Incident records are buried in general docs instead of isolated under an operations/history area.
- AWX template names are not reliably sortable by system + intent.
- There is likely historical layering: Terraform-first, then Ansible, then GitOps/app manifests, then operational runbooks.

## Initial Classification Model
For planning purposes, current repo content appears to map into these concerns:
- **deployment/provisioning**: Terraform, cloud-init templates, initial install playbooks/scripts
- **configuration/state**: app manifests, cluster-config, networking, storage, inventory/vars
- **operations**: checks, patching, sync jobs, routine maintenance, AWX automation
- **recovery**: backups, restores, rebuilds, resurrection artifacts, disaster recovery notes
- **documentation**: onboarding, architecture, setup guides, reference docs, change history
- **history/evidence**: RCAs, completion summaries, audit logs

## Milestone Status
- Phase 1 inventory/classification: in progress, now refined with targeted Ansible/AWX/script/doc evidence
- Phase 2 pain points/overlaps: in progress, substantive findings captured
- Phase 3 target information architecture: not yet finalized in this file
- Phase 4 naming conventions: in progress, with concrete artifact examples and one confirmed AWX schedule/template mismatch
- Phase 5 transition sequencing: not started here

## Additional Evidence from 2026-04-02 Run

### Focus areas reviewed today
- top-level repo inventory (sanity check against the first-pass classification)
- `ansible/playbooks/` file layout
- `ansible/job-templates/` contents
- `ansible/awx-job-templates.yml` template and schedule naming details
- `scripts/` file layout and naming patterns
- flat `docs/` sample inventory

### New observations

#### 1. Ansible playbooks are split by host/service, patch task, and maintenance utility all in one directory
Top-level `ansible/playbooks/` currently mixes several artifact types:
- host/service deploy/configure playbooks: `clawdbot.yml`, `frigate.yml`, `pbs.yml`, `motioneye.yml`, `octoprint.yml`, `proxmox.yml`
- patch/operate tasks: `patch-debian.yml`, `patch-kubernetes-node.yml`, `patch-proxmox.yml`, `check-updates.yml`
- recovery/special operations: `clawdbot-resurrection.yml`, `distribute-clawdbot-ssh-key.yml`
- generic maintenance utilities under `maintenance/`: `backup.yml`, `restore.yml`, `join_proxmox_cluster.yml`, `disable_wdmd.yml`, `install_argocd.yml`

This strengthens the case for intent-based subdirectories because the current shape requires knowing repo lore rather than just operator intent.

#### 2. `maintenance/` is a catch-all, not a true lifecycle boundary
The `maintenance/` subtree currently includes:
- backup/recovery (`backup.yml`, `restore.yml`)
- cluster operations (`join_proxmox_cluster.yml`, `disable_wdmd.yml`)
- provisioning/configuration (`install_argocd.yml`, `create_template.yml`, `generate_awx_ssh_key.yml`)

So `maintenance` is really functioning as “miscellaneous operational leftovers,” which is useful evidence for replacing that label rather than preserving it.

#### 3. AWX naming inconsistency is now confirmed, not just suspected
Targeted review of `ansible/awx-job-templates.yml` confirmed several concrete issues:
- the same file uses both action-first (`Deploy - Frigate NVR`) and system-first (`Proxmox - Configure Node`, `MotionEye - Deploy camera2`) naming families
- `Maintenance - Deploy PBS Server` is clearly deployment/configuration work, not maintenance
- `Ad-hoc - Check Pending Updates` is operator-facing routine audit/inspection, not truly generic ad-hoc execution
- `Distribute Clawdbot SSH Key` has no domain prefix at all, so it sorts oddly beside the other templates
- **confirmed mismatch:** schedules for daily Kubernetes patching reference `Patch - Kubernetes Node`, while the defined job template is `Patch - Kubernetes Nodes`

That last mismatch is especially useful for the transition plan because it shows naming cleanup is not just cosmetic; it also reduces config drift and operator error.

#### 4. Scripts show mostly decent imperative naming, with a few obvious historical outliers
The `scripts/` tree is closer to a workable standard than AWX/playbooks, but it still mixes concerns and conventions:
- solid imperative names: `backup-configs.sh`, `restore-configs.sh`, `check-cluster-status.sh`, `sync-awx-inventory.py`
- lifecycle/setup-heavy names: `setup-pbs-user.sh`, `setup-python-env.sh`, `install-argocd.sh`
- migration/audit families already present and useful: `migrate-to-kea.py`, `audit-network.py`
- historical outliers: `install-proxmenux.sh`, `cleanup-old-proxmenux.sh`
- non-runtime note files mixed directly into the executable tree: `PYTHON-SETUP.md`, `README-analyze-opnsense.md`, `UPTIME-KUMA-SYNC-FIX.md`

This suggests the script plan should address both naming and placement, especially whether note/docs files should stay under `scripts/` or move under a docs/reference area.

#### 5. Flat docs inventory reinforces the need for lifecycle-based doc buckets
A quick sample of `docs/` shows at least five distinct doc types currently interleaved:
- setup/deployment guides (`clawdbot-deployment.md`, `frigate-deployment-guide.md`, `pbs-setup-guide.md`)
- quick references (`pbs-quick-reference.md`, `proxmenux-quick-reference.md`)
- migration/planning docs (`opnsense-kea-migration-plan.md`)
- design/summary/history docs (`ANSIBLE-IAC-SUMMARY.md`, `K8S-ANSIBLE-COMPLETE.md`)
- incident/RCA files (`rca-*`, `frigate-outage-rca-2026-03-22.md`)

The issue is not that any one document is misplaced; it is that the directory currently has almost no lifecycle boundaries at all.

## Open Questions
1. Should this repo remain a single “everything homelab infra” repo, or should the reorg plan explicitly preserve room for later repo splits?
2. Should incident/RCA history stay inside `k8s-2025`, or move to a dedicated operations history area if discoverability matters more than strict repo locality?
3. How strongly should AWX naming prioritize sortability by system vs action?
4. Is `alfred/` intentionally inside this repo as managed infrastructure content, or should it be treated as a recovery artifact bundle only?

## Notes from 2026-04-01 Run
Reviewed today:
- root repo layout (top-level inventory)
- `README.md`
- `ARCHITECTURE.md`
- `BACKUP.md`
- `docs/README.md`
- `ansible/playbooks/maintenance/README.md`
- `ansible/awx-job-templates.yml`
- file listings for `ansible/playbooks`, `scripts`, `docs`, `applications`, `cluster-config`, `networking`, `storage`

What changed today:
- created this assessment file
- documented current structure, mixed concerns, naming inconsistency, and first-pass problem statements

## 2026-04-03 Validation Update

A targeted validation pass shows the repo is no longer in the pre-reorg state assumed by the earlier planning notes.

### Current state confirmed in repo
- root now already uses a cleaner high-level split: `terraform/`, `config/`, `operations/`, `recovery/`, `docs/`, `ansible/`, `alfred/`
- recovery docs previously assumed to be at root have been moved:
  - `recovery/backups/backup-and-restore-guide.md`
  - `recovery/rebuild/rebuild-from-scratch.md`
- incident and audit material are already separated from general docs:
  - `operations/incidents/`
  - `operations/audits/logs/`
- config content is already consolidated under `config/` with intact subtrees:
  - `config/applications/`
  - `config/cluster-config/`
  - `config/networking/`
  - `config/storage/`
- Ansible playbooks are already intent-split under `ansible/playbooks/`:
  - `bootstrap/`, `deploy/`, `operate/`, `recover/`
- `alfred/` remains an active service area, while Alfred recovery artifacts have been split out to `recovery/service-recovery/alfred/`

### Evidence reviewed today
- root listing and root markdown inventory
- `alfred/README.md`
- `config/cluster-config/README.md`
- `config/cluster-config/argocd-apps/README.md`
- `ansible/playbooks/README.md`
- `docs/archive/reorg-execution-log-2026-04-02.md`

### Assessment change
The main planning problem has shifted from "design the target structure" to "validate the execution, document residual inconsistencies, and decide whether any second-pass cleanup is still worth the churn."

### Residual pain points still visible
- some planning docs in `workspace/plans/` still describe the older pre-execution layout and needed correction
- docs are much better bucketed, but a few root-level docs under `docs/` still look like candidates for later reclassification
- naming normalization appears partial rather than universal; playbook filenames were largely kept stable while directory intent improved
- `alfred/` now clearly behaves as an active automation/service area, so older uncertainty about it being recovery-only should be retired
- several top-level directories remain outside the newer taxonomy by design or deferral (`cloud-init-templates/`, `scripts/`, `kubernetes/`), so the repo is cleaner but not doctrinaire

### Follow-up validation from later 2026-04-03 pass
- `docs/network-audit-process.md` behaves like an operator guide/runbook and is the strongest candidate to move under `docs/guides/` or `operations/runbooks/` in a later tidy-up wave
- `docs/opnsense-dns-dhcp-recommendations.md` behaves like generated reference/report output, so `docs/reference/` or `operations/audits/` is a better long-term fit than docs root
- live AWX template naming is in much better shape than the earlier draft implied: the previously confirmed `Patch - Kubernetes Node` vs `Patch - Kubernetes Nodes` mismatch is gone, and purpose-first names dominate the file
- the only remaining `Maintenance - ...` / `Ad-hoc - ...` strings in AWX config are commented examples, not active template definitions
- the biggest remaining naming inconsistency is therefore not AWX but conservative playbook filenames such as `backup.yml`, `restore.yml`, and `check_cluster.yml`, which may now be acceptable because the intent directories already provide context
