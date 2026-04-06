# k8s-2025 Transition Plan

Last updated: 2026-04-06
Status: Transition largely executed; plan now tracks validation and residual cleanup

## Objective
Move from the current mixed-layout repository to the proposed intent-based structure with minimal operator confusion and low breakage risk.

## Transition Strategy
Use a staged migration, not a heroic weekend of regret.

## Stage 0 - Preparation
- Freeze the target information architecture and naming convention decisions.
- Inventory path-sensitive items before moving files:
  - AWX job template playbook paths
  - shell/python scripts with hard-coded repo paths
  - docs with relative links
  - README references
  - automation using repo root assumptions
- Define acceptance checks for each stage.

### Preparation deliverables
- path reference inventory
- move map (old path → new path)
- rollback notes per stage
- naming dependency inventory (template names, schedule names, documented launch names)

### Preparation findings added on 2026-04-02
- `ansible/awx-job-templates.yml` contains a live-looking naming dependency mismatch: daily schedules reference `Patch - Kubernetes Node`, while the defined template is `Patch - Kubernetes Nodes`
- AWX and docs reference job template names directly, so naming changes must be staged with search/update validation rather than treated as harmless cosmetic edits
- several scripts and playbooks have historical names (`proxmenux`, generic `backup.yml` / `restore.yml`) that will be easier to relocate safely if they are first mapped to canonical intent labels

## Stage 1 - Documentation-only restructuring
Safest early win.

Actions:
- create destination doc folders
- move or classify docs into architecture/guides/reference/archive/incidents
- leave short index pages or redirect notes where helpful
- keep content unchanged except for path/link fixes

Validation:
- README links work
- no missing key operator docs
- RCA archive is easy to browse

Rollback:
- git revert doc moves

## Stage 2 - Naming normalization without major moves
Before deep directory churn, fix naming standards and identify exceptions.

Actions:
- standardize AWX template naming patterns in plan/docs first
- standardize playbook and script naming recommendations
- identify files that should be renamed before or during moves

Validation:
- naming rubric covers most active files/templates
- known collisions or ambiguities documented

Rollback:
- not applicable for planning phase; later execution should batch renames by domain

## Stage 3 - Introduce new top-level intent directories
Create target directories while minimizing immediate file movement.

Actions:
- create `provision/`, `config/`, `operations/`, `recovery/`
- optionally restructure `docs/` at same time if not already done
- move small, low-risk areas first:
  - `audit-logs/` → `operations/audits/`
  - RCA docs → `operations/incidents/`
  - `alfred/recovery/` → `recovery/service-recovery/alfred/`

Validation:
- operator can locate audits/incidents/recovery assets faster
- no automation dependencies broken

Rollback:
- git revert moved directories

## Stage 4 - Reorganize Ansible by intent
High-value but medium-risk.

Suggested target:
- `provision/ansible/playbooks/deploy/`
- `provision/ansible/playbooks/configure/`
- `provision/ansible/playbooks/operate/`
- `provision/ansible/playbooks/recover/`
- `provision/ansible/awx/`

Actions:
- move AWX definitions and job template files first
- move maintenance playbooks into `operate/` or `recover/`
- then move host/service deploy playbooks into `deploy/` or `configure/`
- update AWX template definitions after file paths are final

Validation:
- `ansible-playbook` commands updated in docs/examples
- AWX import file paths all resolve
- inventory/role/file references still work

Rollback:
- preserve a single commit or tightly grouped commits per move set
- re-import prior AWX job template definitions if needed

## Stage 5 - Reorganize scripts by operator intent
Medium value, medium risk.

Actions:
- split `scripts/` into bootstrap/deploy/ops/migration or similar
- group AWX helper scripts near Ansible AWX config
- group backup/restore scripts with recovery or ops depending on use case

Validation:
- shebang-based executability preserved
- docs/examples updated
- no cron/AWX/local wrapper uses broken

Rollback:
- revert script move batch

## Stage 6 - Reorganize config/state trees
Potentially larger change but conceptually clean.

Actions:
- group `applications/`, `cluster-config/`, `networking/`, `storage/` under `config/`
- make GitOps relationship explicit with README/index docs
- update kustomize/manifests/docs accordingly

Validation:
- kustomize paths resolve
- ArgoCD app definitions reference correct locations
- docs still match repo reality

Rollback:
- revert in domain-based commits

## Stage 7 - Terraform relocation (optional/deferred)
Potentially the highest path/tooling sensitivity.

Options:
1. Keep Terraform at root indefinitely
2. Move Terraform under `terraform/` only after all scripts/docs/tooling are audited

Recommendation:
- defer unless there is a strong benefit and tooling impact is understood

Validation:
- `terraform init/plan` works from new location
- any wrappers/docs updated

Rollback:
- move `.tf` files back to root

## Risk Controls
- move one concern-area at a time
- prefer commit batches that can be reverted cleanly
- update docs and paths in the same commit as the move
- keep a temporary compatibility index for major relocated docs
- validate AWX references before importing template changes
- if execution happens later, do not rename and relocate the same high-risk files in giant mixed commits

## Validation Checklist for Execution Phase
- root README reflects new layout
- top-level directory purpose is obvious
- all referenced Ansible playbooks exist at stated paths
- AWX job templates import cleanly
- scripts referenced by docs still exist at documented paths
- ArgoCD/Kustomize paths resolve
- backup/recovery runbooks still point to real assets

## Open Decisions
- whether Terraform remains at root
- whether incidents stay under `docs/` or move to `operations/incidents/`
- whether `alfred/` becomes recovery-only or remains a service deployment area
- whether `scripts/` should remain globally visible or become domain-local
- whether AWX naming should be normalized before path moves, or in the same execution wave per domain

## Current Transition Bias
Based on today’s evidence, the safest execution order still looks like:
1. docs/history classification
2. AWX/playbook/script naming normalization plan
3. low-risk operations/recovery moves
4. Ansible/AWX structural moves
5. config tree moves
6. optional Terraform relocation

That sequence reduces the odds of compounding path churn with naming churn in the same fragile areas.

## 2026-04-03 Validation Update

The staged transition described above was largely executed on 2026-04-02, as documented in `k8s-2025/docs/archive/reorg-execution-log-2026-04-02.md`.

### Stages effectively completed
- Stage 1: docs/history classification
- Stage 2: low-risk operations/recovery moves
- Stage 3: Ansible / AWX structure
- Stage 4: script-doc cleanup
- Stage 5: conservative config tree consolidation
- Stage 6: Terraform relocation
- Stage 7: documentation hygiene and secret scrubbing
- Stage 8: AWX template naming normalization

### Transition-plan role now
This file should now function as:
- a record of the intended safe sequencing
- a checklist for post-move validation and residual cleanup
- a guide for any future second-pass tidy-up work

### Remaining validation / cleanup items
1. confirm whether any planning docs, runbooks, or archived summaries still over-describe the old layout in ways that confuse operators
2. finish the low-risk docs-root classification pass:
   - `docs/network-audit-process.md` is likely a guide/runbook
   - `docs/opnsense-dns-dhcp-recommendations.md` is likely reference or audit output
3. do a narrow residual naming audit focused on playbook filenames; AWX template names now appear largely normalized in active config
4. decide whether there is any benefit in a later `ansible/` top-level relocation, or whether churn would now outweigh clarity gains
5. decide whether remaining top-level exceptions (`cloud-init-templates/`, `scripts/`, `kubernetes/`) should be left as stable exceptions or folded into a later cleanup wave

### Rollback note
At this point the meaningful rollback path is Git history, not further planning. The structure has already crossed from proposal into lived reality.

## 2026-04-04 Refinement Update

The transition sequence now looks effectively complete enough that the next safe wave, if Al ever wants one, should be tiny and boring.

### Suggested residual execution order
1. move `docs/network-audit-process.md` to `docs/guides/` **or** `operations/runbooks/`
2. move `docs/opnsense-dns-dhcp-recommendations.md` to `operations/audits/` **or** `docs/reference/`
3. update `docs/README.md` so it no longer lists those docs as temporary root exceptions
4. refresh `ansible/playbooks/README.md` so it describes the current `bootstrap/`, `deploy/`, `operate/`, and `recover/` split instead of the old maintenance-centric worldview
5. stop there unless an operator-facing naming pain point remains visible

### Validation notes from today
- the AWX config is no longer the fragile naming hotspot it was earlier in planning; active names now look consistent enough
- the most likely low-risk cleanup is document relocation plus explanatory README updates
- renaming conservative playbook filenames in the current tree would add churn but little safety or clarity, so it should stay below the line unless a real usability issue is found

## 2026-04-05 Refinement Update

### Residual transition sequence (tightened)
The next safe wave is now even narrower than yesterday’s draft implied:
1. classify `docs/network-audit-process.md`
2. classify `docs/opnsense-dns-dhcp-recommendations.md`
3. update `docs/README.md` to remove the temporary-holdout note if both moves happen
4. replace `ansible/playbooks/README.md` with a true index of the current playbook intent split
5. stop

### Why this sequence is now preferred
- `docs/README.md` is already truthful, so it only needs a small follow-up after the doc moves actually happen
- `ansible/playbooks/README.md` is the main remaining explanatory drift and can be fixed independently of any path changes
- no fresh evidence today suggests a need for further directory restructuring, playbook renaming, or AWX naming churn

### Risk note
If execution resumes later, avoid bundling the README rewrite with unrelated renames. A tiny doc-only commit series is the safest finish.

## 2026-04-06 Refinement Update

Today’s validation pass changes the transition plan in one important way: there is no longer an obvious mandatory "next wave."

### Current transition status
- the structure is already in the target neighborhood
- the README/doc alignment issues previously called out are now resolved
- the remaining oddities are mostly legacy names or pragmatic top-level exceptions rather than broken transitions

### Recommended transition closure criteria
Consider the reorganization transition effectively complete when Al agrees with these statements:
1. the main operator surfaces are easy to find by intent
2. no critical docs still describe the old layout in misleading ways
3. remaining exceptions (`scripts/`, `cloud-init-templates/`, `kubernetes/`) are accepted as intentional
4. any future renames are justified by concrete usability issues, not symmetry cravings

### If a follow-up execution wave ever happens
Keep it tiny and evidence-driven:
1. rename lingering `proxmenux` artifacts only after checking for external references
2. optionally re-home `cloud-init-templates/README-HOMEASSISTANT.md` if it behaves more like docs than a local package note
3. stop again

### Transition recommendation
From a planning perspective, the transition plan is now complete enough to present. The next responsible move is review/approval, not more structural design.
