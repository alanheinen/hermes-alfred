# Network Performance Optimization Plan

## Goal
Identify and eliminate bottlenecks, establish performance baselines, and continuously optimize your homelab network.

## Phase 1: Baseline & Discovery (Week 1)

### Current State Assessment
**Tasks:**
- Network topology audit (switches, VLANs, routes)
- Bandwidth utilization baseline (internal + external)
- Latency measurements (host-to-host, VM-to-VM, pod-to-pod)
- Storage performance (iSCSI throughput, latency)
- DNS resolution times
- Application response times (ingress endpoints)

**What I need from you:**
- Network diagram (if you have one, otherwise I'll generate from discovery)
- Access to OPNsense/router (read-only API or config dump)
- Switch configs (or access to managed switches)
- Expected performance targets (e.g., "iSCSI should be X MB/s")

### Monitoring Setup
**Tools to deploy (if not present):**
- Prometheus + node_exporter on all hosts
- Grafana dashboards for visualization
- cAdvisor for container metrics
- Speedtest-cli for WAN baseline

**What I need from you:**
- Where to deploy monitoring stack (K8s cluster? Dedicated VM?)
- Retention period for metrics (1 week? 1 month?)
- External monitoring targets (websites, APIs you depend on)

## Phase 2: Quick Wins (Week 2)

### Low-Hanging Fruit
**Checks:**
- MTU optimization (jumbo frames for iSCSI?)
- DNS caching and resolver performance
- Duplicate ARP/MAC issues
- Slow database queries (if applicable)
- Chatty services (excessive API calls, polling)
- Certificate validation overhead

**Potential Fixes:**
- Enable jumbo frames on storage network
- Deploy local DNS cache (CoreDNS tweaks, Pi-hole optimization)
- Tune iSCSI multipath settings
- Optimize Flannel MTU/backend
- Review MetalLB ARP/BGP mode
- Connection pooling for databases

**What I need from you:**
- Permission to make non-destructive config changes
- Rollback plan comfort level (can I YOLO it, or do you want approval first?)
- Testing window (can I disrupt traffic briefly for tests?)

## Phase 3: Deep Optimization (Weeks 3-4)

### Storage Layer
- iSCSI tuning (queue depth, block size, caching)
- democratic-csi optimization
- PVC performance testing and benchmarking
- TrueNAS ZFS tuning (if needed)

### Network Layer
- VLAN segmentation review (is traffic isolated properly?)
- QoS policies (prioritize K8s control plane traffic?)
- BGP vs ARP mode for MetalLB (if applicable)
- Ingress controller tuning (worker threads, buffer sizes)

### Kubernetes Layer
- Pod resource limits tuning (prevent noisy neighbors)
- CNI optimization (Flannel vs Calico performance)
- Service mesh evaluation (do you need it? is it slowing you down?)
- Image pull optimization (local registry/cache)

**What I need from you:**
- Your tolerance for complexity (simple and stable vs bleeding-edge fast)
- Workload priorities (which apps matter most?)
- Downtime windows for disruptive changes

## Phase 4: Continuous Monitoring & Alerts (Ongoing)

### Proactive Alerts
- Bandwidth saturation warnings
- Latency spikes
- Packet loss detection
- Storage I/O wait spikes
- DNS resolution failures

### Weekly Performance Report
- Trend analysis (getting faster or slower?)
- Anomaly detection (unusual patterns)
- Capacity planning (when will you run out of resources?)
- Optimization opportunities

**What I need from you:**
- Alert thresholds (what's "normal" vs "problem"?)
- How often do you want reports? (weekly? monthly?)

## Expected Outcomes
- 10-30% improvement in storage throughput (via iSCSI tuning)
- 20-50ms reduction in pod-to-pod latency (via CNI optimization)
- Reduced DNS lookup times (via caching)
- Clear visibility into bottlenecks (via monitoring)
- Proactive capacity planning (no more surprise outages)

## Next Steps
1. Provide network diagram or consent for me to discover/map it
2. Grant access to monitoring/config systems
3. Define testing windows and risk tolerance
4. I'll deploy baseline monitoring this weekend
5. First performance report by end of Week 1
