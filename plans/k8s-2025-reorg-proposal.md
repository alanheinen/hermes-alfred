# k8s-2025 Reorganization Proposal

Last updated: 2026-04-04
Status: Proposal mostly realized in repo; now serving as validation baseline

## Goal
Reorganize `k8s-2025` so operators can answer three questions quickly:
1. How do I deploy or change infrastructure?
2. Where is the authoritative configuration/state for a system?
3. How do I operate, troubleshoot, or recover it?

## Design Principles
- Separate **provisioning**, **configuration**, **operations**, **recovery**, and **docs/history** concerns.
- Keep the root concise: landing page plus only the files that must stay there for tooling or Terraform execution.
- Prefer directories that reflect operator intent rather than implementation accidents.
- Make names sortable and guessable.
- Avoid breaking everything at once; use staged moves with compatibility shims only where needed.

## Proposed Target Structure (draft)

```text
k8s-2025/
├── README.md
├── CHANGELOG.md
├── terraform/                    # provisioning/IaC root for Terraform files
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform-*.tf
│   ├── terraform.tfvars.example
│   └── modules/                  # if introduced later
├── provision/
│   ├── cloud-init/
│   ├── ansible/
│   │   ├── playbooks/
│   │   │   ├── deploy/
│   │   │   ├── configure/
│   │   │   ├── operate/
│   │   │   ├── recover/
│   │   │   └── site.yml
│   │   ├── inventory/
│   │   ├── roles/
│   │   ├── vars/
│   │   ├── files/
│   │   └── awx/
│   └── scripts/
│       ├── bootstrap/
│       ├── deploy/
│       ├── ops/
│       └── migration/
├── config/
│   ├── cluster/
│   ├── networking/
│   ├── storage/
│   ├── applications/
│   └── registry/
├── operations/
│   ├── runbooks/
│   ├── monitoring/
│   ├── audits/
│   └── incidents/
├── recovery/
│   ├── backups/
│   ├── rebuild/
│   ├── host-recovery/
│   └── service-recovery/
└── docs/
    ├── architecture/
    ├── guides/
    ├── reference/
    ├── decisions/
    └── archive/
```

## Mapping from Current Structure to Proposed Structure

### Provisioning / deployment
Current:
- root Terraform files
- `cloud-init-templates/`
- `ansible/`
- parts of `scripts/`

Proposed:
- move Terraform working files under `terraform/` if tooling impact is acceptable
- rename `cloud-init-templates/` → `provision/cloud-init/`
- move `ansible/` → `provision/ansible/`
- split `scripts/` by intent under `provision/scripts/`

### Configuration / declarative state
Current:
- `applications/`
- `cluster-config/`
- `networking/`
- `storage/`

Proposed:
- place under `config/`
- make GitOps relationship explicit:
  - `config/applications/` = workload manifests/kustomizations
  - `config/cluster/argocd-apps/` = ArgoCD application definitions
  - `config/cluster/registry/` or `config/registry/` for registry credentials and service account defaults

### Operations
Current:
- `docs/rca-*`
- `audit-logs/`
- `ansible/playbooks/maintenance/`
- many operational scripts in `scripts/`

Proposed:
- `operations/incidents/` for RCA files
- `operations/audits/` for audit logs and audit tooling docs
- `operations/runbooks/` for quick reference / day-2 procedures
- operational Ansible playbooks under `provision/ansible/playbooks/operate/`

### Recovery
Current:
- `BACKUP.md`
- `REBUILD-FROM-SCRATCH.md`
- `alfred/recovery/`
- maintenance playbooks `backup.yml`, `restore.yml`

Proposed:
- `recovery/backups/` for backup/restore docs and supporting artifacts
- `recovery/rebuild/` for rebuild-from-scratch content
- `recovery/service-recovery/alfred/` for Alfred/OpenClaw-specific recovery bundle
- recovery Ansible playbooks under `provision/ansible/playbooks/recover/`

### Documentation
Current:
- large flat `docs/`
- multiple root-level quickstart/setup docs

Proposed:
- reserve root docs for only the main entry points
- move detailed content into scoped `docs/` sections:
  - `docs/architecture/`
  - `docs/guides/`
  - `docs/reference/`
  - `docs/decisions/`
  - `docs/archive/` for old completion summaries and transient milestone documents

## Recommended Practical Variant
If moving Terraform out of root would cause too much churn right now, use a lighter version:
- keep Terraform files at root temporarily
- still introduce `provision/`, `config/`, `operations/`, `recovery/`, and a better-structured `docs/`
- defer Terraform relocation to a later cleanup phase

That likely gives most of the value with less breakage.

## Refinement from 2026-04-02 Review

### Stronger recommendation: separate by operator intent first, tool second
Today’s targeted inventory supports a more opinionated rule:
- first split by **what the operator is trying to do** (`provision`, `config`, `operations`, `recovery`)
- then split by tool or mechanism inside that boundary (`ansible`, `scripts`, manifests, docs)

That means the near-term proposal should avoid simply moving everything under a giant `provision/ansible/` bucket and calling it done. The real value comes from making deploy/configure/operate/recover boundaries visible.

### Practical target layout for Ansible/AWX
A more concrete Ansible target that fits the actual repo shape:

```text
provision/
  ansible/
    inventory/
    roles/
    vars/
    playbooks/
      deploy/
      configure/
      operate/
      recover/
    awx/
      job-templates.yml
      job-templates/
```

Why this variant looks better than the current structure:
- top-level playbooks are no longer forced to coexist with patching and recovery tasks
- the current `maintenance/` catch-all can be dissolved instead of preserved
- AWX template definitions become an explicit operator surface rather than an implementation sidecar

### Practical target layout for docs/history
The docs review also suggests using a split that reflects document lifecycle more clearly than the first draft:
- `docs/architecture/` — system architecture and design rationale
- `docs/guides/` — setup, deployment, migration, and operator walkthroughs
- `docs/reference/` — quick references, lookup material, config references
- `docs/archive/` — completion summaries, historical milestone notes, superseded one-off summaries
- `operations/incidents/` — incident and RCA files, kept near operations instead of buried in general docs

### Practical target layout for scripts
The scripts inventory suggests a modest rule set:
- executable automation stays in a scripts area but should be grouped by intent (`bootstrap`, `deploy`, `ops`, `migrate`, `audit`, `sync`)
- Markdown note files currently living under `scripts/` should move to `docs/reference/` unless they are tightly bound to a single script family
- legacy one-off names like `proxmenux` should be normalized or explicitly documented as compatibility exceptions

## Proposal Maturity
This is still not fully presentation-ready, but it is no longer hand-wavy. The main structure is coherent, and the next refinement pass should focus on a concrete move map rather than inventing new buckets.

## First-Pass Placement Recommendations
- `alfred/` should likely become `recovery/service-recovery/alfred/` unless it is an actively managed deployable service root
- `audit-logs/` should become `operations/audits/`
- `docs/rca-*` should become `operations/incidents/`
- `docs/*quick-reference*` should become `docs/reference/`
- `docs/*setup*`, `*deployment*`, and migration guides should become `docs/guides/`
- old summary/completion files should become `docs/archive/`
- `ansible/job-templates/` and `ansible/awx-job-templates.yml` should become an obvious AWX area under Ansible, such as `provision/ansible/awx/`

## Benefits
- Faster navigation by operator intent
- Cleaner boundary between desired state and day-2 operations
- Easier onboarding for future Al, who deserves better than archaeological field work at 4:15 AM
- Better AWX/playbook discoverability after naming cleanup
- More defensible proposal for later incremental execution

## Risks / Tradeoffs
- Some path-sensitive scripts, docs, and AWX references will break if moves happen carelessly
- Git history becomes slightly less intuitive for moved files unless documented well
- A perfect taxonomy is less important than a stable, teachable one

## 2026-04-03 Validation Update

The proposal has been substantially realized in the repository already. The target shape described here is therefore best treated as a validation baseline and explanation of the current information architecture, not merely a future-state sketch.

### What is now already true
- Terraform has moved under `terraform/`
- config/state trees have moved under `config/`
- recovery content has moved under `recovery/`
- incident and audit material have moved under `operations/`
- docs are split into `architecture/`, `guides/`, `reference/`, and `archive/`
- Ansible playbooks are split by intent under `ansible/playbooks/{bootstrap,deploy,operate,recover}`

### Proposal adjustment
The remaining value of this proposal is to:
- explain why the current structure is sensible
- identify any mismatches between the intended taxonomy and what actually landed
- guide small second-pass refinements rather than a major first execution wave

### Residual refinement candidates
- decide whether `ansible/` should remain top-level long term or move under a broader provisioning bucket in a later cleanup
- classify the remaining `docs/*.md` files at docs root with a bias toward:
  - `docs/network-audit-process.md` → `docs/guides/` or `operations/runbooks/`
  - `docs/opnsense-dns-dhcp-recommendations.md` → `docs/reference/` or `operations/audits/`
- review whether playbook filenames should stay historically stable or be normalized further now that intent directories exist
- decide whether top-level exceptions such as `cloud-init-templates/`, `scripts/`, and `kubernetes/` are worth folding into a stricter taxonomy, or should remain explicit pragmatic exceptions
- verify that AWX naming normalization is complete enough for operators, rather than just technically less messy

### Practical stance after follow-up validation
The repo now looks best when treated as an intent-first structure with a few pragmatic top-level exceptions, not as a purity contest. In other words: keep the strong buckets, classify the remaining stray docs, and resist further churn unless it buys real discoverability.

## Proposal Maturity
This is now presentation-ready as an explanation of the reorganized structure and the rationale behind it. What remains is refinement, not invention.

## 2026-04-04 Refinement Update

Today’s pass sharpens the proposal in one specific way: it treats the remaining repo-root oddities as **intentional cleanup candidates**, not evidence that the broader structure is unfinished.

### Recommended placement decisions
- `docs/network-audit-process.md`
  - preferred destination: `docs/guides/`
  - rationale: it is a how-to/runbook style document covering execution, schedules, troubleshooting, and operational practice
  - alternate destination: `operations/runbooks/` if Al wants all ongoing procedures grouped under operations rather than general guides
- `docs/opnsense-dns-dhcp-recommendations.md`
  - preferred destination: `operations/audits/`
  - rationale: it is generated assessment output tied to an audit/analysis activity, not evergreen reader-facing guidance
  - alternate destination: `docs/reference/` if he prefers keeping generated reference artifacts under docs instead of operations

### Practical proposal stance
- keep the current top-level architecture as-is; it already communicates provisioning/config/state, operations, recovery, and docs cleanly enough
- accept a few pragmatic top-level exceptions (`scripts/`, `cloud-init-templates/`, `kubernetes/`) unless a future cleanup produces a concrete operator benefit
- favor documentation alignment over further path churn
- treat filename normalization as optional polish, not as required completion criteria

### What would make the proposal materially better from here
Not more buckets. Just a small move map for the two docs-root files plus a note that `ansible/playbooks/README.md` should be refreshed to match the post-reorg layout.
