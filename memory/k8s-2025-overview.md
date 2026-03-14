# k8s-2025 Repository Overview

**Location:** `/home/aheinen/.openclaw/workspace/k8s-2025`
**Purpose:** Production-grade HA Kubernetes cluster on Proxmox homelab infrastructure
**Last reviewed:** 2026-02-13

---

## Infrastructure Layout

### Proxmox Cluster (6 nodes)
| Host | IP | Hosts |
|------|-----|-------|
| one.lan | 172.16.1.121 | k8s1 |
| two.lan | 172.16.1.122 | k8s2 |
| three.lan | 172.16.1.123 | k8s3, Home Assistant |
| four.lan | 172.16.1.124 | k8s4 |
| five.lan | 172.16.1.125 | k8s5, Bastion |
| vm01.lan | 172.16.1.141 | k8s6, PBS |

### Kubernetes Nodes (6 VMs, each 4 vCPU / 8GB RAM / 40GB disk on local-zfs)
| Node | IP | Role |
|------|-----|------|
| k8s1 | 172.16.1.201 | Control Plane + Worker + HAProxy + keepalived (MASTER, pri 101) |
| k8s2 | 172.16.1.202 | Control Plane + Worker + HAProxy + keepalived (BACKUP, pri 100) |
| k8s3 | 172.16.1.203 | Control Plane + Worker + HAProxy + keepalived (BACKUP, pri 99) |
| k8s4 | 172.16.1.204 | Worker |
| k8s5 | 172.16.1.205 | Worker |
| k8s6 | 172.16.1.206 | Worker |

**Total cluster resources:** 24 vCPUs, 48 GB RAM, 240 GB disk

### Other Infrastructure VMs
- **PBS** (VM 103) — 172.16.1.183 on vm01.lan — Proxmox Backup Server
- **Bastion** (VM 101) — 172.16.1.184 on five.lan — SSH bastion with 2FA + fail2ban
- **Home Assistant** (VM 100) — 172.16.1.160 on three.lan — HAOS via tteck script
- **PXE Server** (VM 102) — 172.16.1.115 on two.lan — netboot.xyz
- **ClawdBot** — OpenClaw deployment (has its own Terraform + Ansible role)

---

## High Availability

- **VIP:** 172.16.1.120 (k8s-control.lan) managed by keepalived VRRP
- **HAProxy** on k8s1-3 load-balances API requests to port 6444 on each control plane
- **etcd:** 3-node quorum, tolerates 1 failure
- **Control plane taints removed** — all 6 nodes run workloads

---

## Software Stack

- **OS:** Ubuntu 24.04 LTS
- **Kubernetes:** v1.31 (kubeadm)
- **Runtime:** containerd (systemd cgroup)
- **CNI:** Flannel (VXLAN)
- **GitOps:** ArgoCD (auto-sync from `applications/` directory)

---

## Networking

| Layer | Detail |
|-------|--------|
| Node network | 172.16.1.0/24, gateway 172.16.1.1 (OPNsense) |
| Pod CIDR | 10.244.0.0/16 (Flannel) |
| Service CIDR | 10.96.0.0/12 |
| MetalLB pool | 172.16.1.170-179 |
| Ingress LB IP | 172.16.1.170 (NGINX Ingress) |
| TLS | cert-manager + Let's Encrypt DNS-01 via AWS Route53 |
| Domain | heinenshome.com |

**Key ports:** 6443 (API via VIP), 6444 (direct API), 8472 (Flannel VXLAN), 112 (VRRP)

---

## Storage

### Proxmox Shared Storage (iSCSI LVM)
- **Source:** TrueNAS SCALE (nas.lan / 172.16.1.101)
- **Zvol:** proxmox-storage/proxmox-lun01 (2 TB)
- **VG:** truenas-vg, storage name `truenas-iscsi`
- **Type:** LVM thick provisioning, shared across all 6 Proxmox nodes
- **Use:** VM disk images, live migration, HA

### Kubernetes Persistent Storage
- **CSI:** democratic-csi (iSCSI) from TrueNAS SCALE
- **Features:** Dynamic provisioning, snapshots, volume expansion
- **Config:** `storage/truenas-scale/values-iscsi.yaml` (gitignored)

---

## Applications Deployed (via ArgoCD)

| App | Description |
|-----|-------------|
| AWX | Ansible automation platform |
| Uptime Kuma | Infrastructure monitoring |
| MeshCommander | Intel AMT management |
| ntfy | Push notifications |
| linuxmag / adminmag | Documentation apps with PVCs |
| Scanopy | App with PostgreSQL backend |
| Network Audit | CronJobs for daily network scanning + weekly diff |

ArgoCD apps defined in `cluster-config/argocd-apps/`, manifests in `applications/`.

---

## Ansible (Primary Automation — ~5,200 LOC)

### Playbooks (in `ansible/playbooks/`)
- **site.yml** — Master (deploys everything)
- **proxmox.yml** — iSCSI + LVM storage on Proxmox
- **pbs.yml** — PBS server + datastore + integration
- **bastion.yml** — SSH bastion with 2FA
- **kubernetes.yml** — Full HA K8s cluster
- **patch-debian.yml / patch-kubernetes-node.yml / patch-proxmox.yml** — Patching
- **truenas-upgrade-apps.yml** — TrueNAS app upgrades
- **clawdbot.yml** — OpenClaw deployment
- **motioneye.yml / octoprint.yml** — IoT device management
- **kea-dhcp-sync.yml** — DHCP sync
- **Maintenance (8):** check_cluster, backup, restore, create_template, install_argocd, fix_user_shell, disable_wdmd, generate_awx_ssh_key

### Roles (17 in `ansible/roles/`)
- **Kubernetes:** k8s_prerequisites, k8s_containerd, k8s_install, k8s_haproxy, k8s_keepalived, k8s_control_plane, k8s_worker, k8s_flannel, k8s_argocd
- **Proxmox:** proxmox_base, proxmox_iscsi, proxmox_storage
- **PBS:** pbs_server, pbs_datastore, pbs_proxmox_integration
- **Other:** bastion_server, common, clawdbot, motioneye, octoprint

### AWX Integration
- AWX deployed on K8s, URL: awx.heinenshome.com
- Inventory auto-synced from `docs/network-inventory.yaml` (29 hosts, 10 groups)
- 10 job templates, 1 workflow, 4 schedules defined in `ansible/awx-job-templates.yml`
- Import script: `scripts/import-awx-job-templates.py`

---

## Terraform Resources

### Provider
- `bpg/proxmox` (Proxmox Virtual Environment provider)

### Resources in `main.tf`
- `proxmox_virtual_environment_vm.k8s_nodes` — k8s2-k8s6 (for_each, cloned from template 9000)
- `proxmox_virtual_environment_vm.k8s1` — k8s1 (created last via depends_on)
- `null_resource.get_argocd_password` — Retrieves ArgoCD password after init

### Additional Terraform files
- `terraform-pbs.tf` — PBS VM (ISO install)
- `terraform-bastion.tf` — Bastion server
- `terraform-pxe.tf` — PXE server
- `terraform-homeassistant.tf` — HA reference (use tteck instead)
- `terraform-clawdbot.tf` — ClawdBot VM

### Key Variables
- Template ID 9000 (Ubuntu 24.04 cloud-init), cloned from node "one"
- VM specs: 4 cores, 8192 MB RAM, 40 GB disk, local-zfs storage
- Cloud-init via uploaded snippets (`local:snippets/{node}-user-data.yml`)

---

## Python Automation Scripts (`scripts/`)

| Script | LOC | Purpose |
|--------|-----|---------|
| sync-awx-inventory.py | 491 | Sync network-inventory.yaml → AWX |
| import-awx-job-templates.py | 606 | Import AWX job templates from YAML |
| sync-uptimekuma-monitors.py | 465 | Sync monitors to Uptime Kuma |
| audit-network.py | 699 | Daily nmap network discovery |
| analyze-opnsense-dns-dhcp.py | 510 | OPNsense config analysis |

---

## Notable Conventions & Patterns

1. **Multi-layer config:** Terraform (VMs) → Cloud-init (bootstrap, now minimal) → Ansible (all config) → ArgoCD (apps)
2. **GitOps:** Apps deployed via ArgoCD from `applications/` dir; `cluster-config/argocd-apps/` has Application CRDs
3. **Secrets management:** Sensitive files gitignored; Ansible Vault for secrets; `.tfvars` never committed
4. **Network inventory as source of truth:** `docs/network-inventory.yaml` drives AWX inventory + Uptime Kuma monitors
5. **One VM per Proxmox host** for K8s nodes — hardware-level redundancy
6. **Cloud-init is legacy** — kept for initial bootstrap but Ansible is the primary deployment method
7. **Comprehensive docs:** 20+ markdown files; CLAUDE.md is the AI-oriented guide; REBUILD-FROM-SCRATCH.md covers bare-metal recovery
8. **Backup via Ansible:** `playbooks/maintenance/backup.yml` and `restore.yml` with encryption support
9. **Network audit pipeline:** Daily CronJob scans → PVC storage → weekly diff comparison
10. **Domain:** heinenshome.com with DNS aliases for services; cert-manager handles TLS via Route53 DNS-01

---

## Key Network Devices (beyond K8s)

- **OPNsense** (172.16.1.1) — Router/firewall, DNS, DHCP
- **TrueNAS SCALE** (172.16.1.101) — NAS with ZFS, iSCSI, runs Jellyfin, Ollama, Frigate, Stirling PDF, AnythingLLM, Glances, Netdata
- **NanoKVM** (172.16.1.180) — KVM-over-IP
- **OctoPi** (172.16.1.161) — 3D printer management
- **46+ IoT devices** — ESP32s, smart plugs, cameras, Google Home, LG appliances, Roborock, etc.
