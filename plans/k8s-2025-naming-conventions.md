# k8s-2025 Naming Conventions

Last updated: 2026-04-06
Status: Conventions drafted; partial repo adoption confirmed

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

## Additional Evidence from 2026-04-02 Review

### AWX templates now grouped by cleanup priority

#### Priority 1: confirmed inconsistency or ambiguity
- `Patch - Kubernetes Nodes` vs schedule references to `Patch - Kubernetes Node`
- `Maintenance - Deploy PBS Server`
- `Ad-hoc - Check Pending Updates`
- `Distribute Clawdbot SSH Key`

#### Priority 2: structurally inconsistent with preferred pattern
- `Proxmox - Configure Node`
- `Proxmox - Join Cluster`
- `OctoPrint - Deploy/Configure`
- `MotionEye - Deploy/Configure`
- `MotionEye - Deploy camera2`
- `MotionEye - Restart Services camera2`

These are all understandable names, but they use different sorting logic and different levels of specificity.

### Suggested canonical remaps for the most obvious examples
- `Maintenance - Deploy PBS Server` → `Deploy - PBS - Server`
- `Ad-hoc - Check Pending Updates` → `Audit - Infrastructure - Pending Updates`
- `Distribute Clawdbot SSH Key` → `Operate - Clawdbot - Distribute SSH Key`
- `Proxmox - Join Cluster` → `Operate - Proxmox - Join Cluster`
- `Proxmox - Configure Node` → `Configure - Proxmox - Node`
- `Patch - Kubernetes Nodes` → keep as family-level template name if one template truly handles plural scope, otherwise rename to something explicit like `Patch - Kubernetes - Rolling Nodes`

### Playbook naming refinement
Today’s inventory suggests the repo should distinguish at least four playbook families:
- deploy/configure service playbooks (`clawdbot.yml`, `frigate.yml`, `pbs.yml`)
- patch/audit/operate playbooks (`patch-debian.yml`, `check-updates.yml`)
- recover/restore playbooks (`clawdbot-resurrection.yml`, `maintenance/restore.yml`)
- cluster utility playbooks (`maintenance/join_proxmox_cluster.yml`, `maintenance/disable_wdmd.yml`)

That supports a canonical naming pattern of:
- `<system>-deploy.yml`
- `<system>-configure.yml`
- `<system>-operate-<task>.yml`
- `<system>-recover-<task>.yml`
- `<system>-patch.yml` or `<system>-patch-<scope>.yml`

### Script naming refinement
The scripts inventory suggests a small compatibility policy is needed:
- normalize clear typos or historical names (`proxmenux`) when execution begins
- keep compatibility wrappers only if external tooling depends on the old name
- move Markdown notes out of `scripts/` unless they are script-family READMEs

## 2026-04-03 Validation Update

A targeted post-execution check suggests the naming work is partly adopted:
- AWX naming normalization was explicitly executed on 2026-04-02 per the repo execution log
- directory-level clarity improved significantly because playbooks are now separated by intent
- playbook filenames themselves appear intentionally conservative and historically stable (for example `backup.yml`, `restore.yml`, `check_cluster.yml`, `clawdbot.yml`), which means filename normalization was deferred more than directory normalization

### Practical interpretation
That is a defensible compromise:
- operators now gain most discoverability from directory intent
- existing AWX/script/doc references faced less churn
- a second naming wave should only happen if the remaining filename inconsistencies still cause real friction

### Remaining naming questions
- should historically short filenames like `backup.yml` and `restore.yml` stay as-is because their directories now provide context?
- should `check_cluster.yml` be normalized to `kubernetes-check-cluster.yml`, or is the current name now good enough inside `operate/`?
- should `cloud-init-templates/` content adopt a more explicit naming/location convention later, or is the current host-focused file naming already adequate?

### Follow-up validation from later 2026-04-03 pass
- active AWX template names now appear consistently purpose-first; the prior `Patch - Kubernetes Node` mismatch has been corrected to `Patch - Kubernetes Nodes`
- residual `Maintenance - ...` and `Ad-hoc - ...` strings in `ansible/awx/job-templates.yml` are commented examples, not live definitions
- the practical naming debate has therefore shifted away from AWX and toward whether conservative playbook filenames deserve a second pass at all
- current evidence argues for restraint: rename only if an operator-facing search/sort problem still exists after the directory split

## Initial Recommendation
For this repo, the immediate naming urgency has dropped. Prioritize only the residual operator-facing inconsistencies that still reduce sortability or cause launch mistakes; avoid renaming stable artifacts merely for aesthetic sport.

## 2026-04-04 Refinement Update

### Naming conclusion from today’s pass
The naming strategy should now explicitly distinguish between **operator-facing names that benefit from uniformity** and **internal filenames whose surrounding directory already supplies the missing context**.

### Operator-facing names worth keeping tight
- AWX job template names
- workflow names
- schedule names
- major guide/reference titles that users browse directly

These are searched and scanned by humans, so consistency pays off.

### Filenames where restraint is now preferable
Examples reviewed today:
- `ansible/playbooks/operate/backup.yml`
- `ansible/playbooks/operate/check_cluster.yml`
- `ansible/playbooks/recover/restore.yml`
- `ansible/playbooks/deploy/clawdbot.yml`

Because the intent directories now provide strong context, these shorter filenames are no longer automatically a problem. A second rename wave should only happen if:
- operators repeatedly misidentify them
- AWX/playbook references become ambiguous
- search results are materially worse than they should be

### Remaining naming/documentation cleanup worth noting
- `ansible/playbooks/README.md` still uses the old maintenance-oriented framing and should be updated when execution resumes
- `docs/network-audit-process.md` would be easier to find if its placement matched its role as a guide/runbook
- `docs/opnsense-dns-dhcp-recommendations.md` would be easier to reason about if its placement matched its role as audit/reference output

### Practical rule going forward
If the directory already answers the "what kind of thing is this?" question, the filename only needs to answer the narrower "which one?" question. That is a much saner standard than renaming half the repo for the aesthetic pleasure of symmetry.

## 2026-04-05 Refinement Update

### Naming conclusion from today’s review
The remaining naming problem is not really filenames. It is **labeling and framing in human-facing index docs**.

### Evidence
- `docs/README.md` uses the current taxonomy correctly and describes the two remaining docs-root exceptions plainly.
- `ansible/playbooks/README.md` still labels the area as "Maintenance Playbooks" even though it documents content from `bootstrap/`, `operate/`, and `recover/` and the live tree also includes `deploy/`.

### Naming/labeling recommendation
- keep current playbook filenames stable unless a real search ambiguity shows up
- prioritize updating index/readme titles and section labels so they reflect the intent-based layout operators now see on disk
- treat README titles, headings, and examples as part of the naming surface because they are often the first thing a human scans before opening files

### Practical implication
If a future cleanup wave only changes names in one place, it should change **human-facing labels first**, not filenames. That buys clarity with almost none of the breakage risk.

## 2026-04-06 Refinement Update

Today’s targeted review narrows the naming problem even further.

### What changed in the naming assessment
- README and index labeling drift is no longer the main issue; the key index files now match the live structure.
- The remaining naming inconsistencies are mostly legacy filenames, especially `proxmenux` in a few script/playbook names.
- Those legacy names are noticeable, but not severe enough to justify blind cleanup without checking for external references first.

### Updated naming recommendation
Prioritize naming work in this order:
1. operator-facing AWX/workflow/schedule names
2. README/index headings and launch examples
3. only then internal filenames with clear evidence of search/sort pain

### Specific low-risk naming candidates
- `scripts/install-proxmenux.sh`
- `scripts/cleanup-old-proxmenux.sh`
- `ansible/playbooks/operate/cleanup-old-proxmenux.yml`

### Naming conclusion
The naming plan is mature enough to present. The repo no longer needs a broad naming crusade; it just has a few elderly labels that may deserve retirement when convenient.
