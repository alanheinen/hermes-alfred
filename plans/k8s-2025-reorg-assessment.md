# k8s-2025 Reorganization Assessment

Last updated: 2026-04-01
Status: Draft in progress

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
- Phase 1 inventory/classification: in progress, good enough for first proposal draft
- Phase 2 pain points/overlaps: in progress, substantive findings captured
- Phase 3 target information architecture: not yet finalized in this file
- Phase 4 naming conventions: initial issues identified
- Phase 5 transition sequencing: not started here

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
