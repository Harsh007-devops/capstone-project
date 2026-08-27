
Phase 8, Task 16: Cost Optimization Report

Current Setup

- GKE Standard cluster, 3 nodes, machine type e2-medium (2 vCPU shared core, 4GB RAM each)
- Autoscaling: min 1, max 3 nodes
- Workload: task-api deployed to dev, test, and prod namespaces, 1-2 replicas each,
  each pod requesting 100m CPU / 128Mi memory (limits: 250m CPU / 256Mi memory)

Observed Utilization (kubectl top, captured after a full day of active use)

Node-level:
  gke-...-fzh7   CPU: 167m (17%)   Memory: 1458Mi (52%)
  gke-...-iw5k   CPU: 238m (25%)   Memory: 1438Mi (51%)
  gke-...-to7l   CPU: 205m (21%)   Memory: 1477Mi (52%)

Pod-level (task-api, actual usage vs. requested):
  dev:  4m CPU used / 100m requested (4%)   43Mi memory used / 128Mi requested (34%)
  prod: 3m CPU used / 100m requested (3%)   46Mi memory used / 128Mi requested (36%)
  test: 3m CPU used / 100m requested (3%)   45Mi memory used / 128Mi requested (35%)

Finding 1: CPU requests are far higher than actual usage, causing scheduling
failures despite low real utilization

During today's build/deploy cycles, multiple pods failed to schedule with
"Insufficient cpu" errors even though node-level actual CPU usage never
exceeded 25%. This is because Kubernetes schedules based on requested
capacity, not actual usage. Between the application pods (100m requested
each, ~13 pod instances across namespaces at peak) and the substantial
per-node system daemon overhead (calico-node, fluentbit-gke, gmp collectors,
konnectivity-agent, netd, ip-masq-agent, node-local-dns, pdcsi-node - each
running 3 copies, one per node), the sum of CPU requests regularly
approached what the small e2-medium nodes could allocate, even though real
usage stayed low.

Recommendation: Lower the task-api CPU request from 100m to 50m (still well
above the ~3-4m actually used, leaving headroom for traffic spikes) and/or
consolidate the node pool to fewer, larger nodes (e.g. 2x e2-standard-2
instead of 3x e2-medium) so system daemonset overhead is paid once per node
across fewer nodes rather than three times.

Finding 2: e2-medium is a shared-core (burstable) machine type

e2-medium provides 2 vCPUs but only 1 physical shared core - CPU delivery can
be inconsistent under load, which compounds Finding 1. For a workload that
needs predictable scheduling (multiple namespaces, CI/CD-driven deploys,
system add-ons like Calico all competing for the same small pool), a
non-shared-core type such as e2-standard-2 costs modestly more per hour but
provides full, dedicated vCPUs, reducing the kind of scheduling contention
seen throughout today's troubleshooting.

Finding 3: Three parallel environments (dev/test/prod) on one small cluster

Running dev, test, and prod as three separate namespace-based environments
inside a single 3-node cluster (rather than dedicated clusters) is a
reasonable and genuinely cost-effective choice for a project this size - it
avoids paying for three separate control planes and node pools. The tradeoff,
visible today, is that all three environments compete for the same limited
CPU/memory pool. For higher-stakes workloads this tradeoff should be
revisited (e.g. dedicated prod cluster), but for the current stage it is the
right cost/complexity balance.

Finding 4: Cluster autoscaler is capped at max_node_count = 3

The Terraform-defined max_node_count = 3 was reached multiple times today,
blocking the autoscaler from adding a 4th node during pod-scheduling
pressure (see Task 14 and Task 15 RCAs). Raising this ceiling would reduce
scheduling failures, but increases cost linearly with each additional node
kept running. Given Finding 1 shows real usage is low, the more
cost-effective fix is reducing requested CPU per pod (so more pods fit in
existing capacity) rather than raising the node ceiling and paying for
capacity that will still be mostly idle.

Summary of Recommended Actions (lowest cost / highest impact first)

1. Reduce task-api CPU/memory requests in the Helm chart and K8s manifests
   (100m to 50m CPU) - no cost increase, directly fixes today's scheduling
   failures.
2. Consider consolidating to 2x e2-standard-2 nodes instead of 3x e2-medium -
   similar or lower total cost, removes shared-core contention, and pays
   system daemonset overhead only twice instead of three times.
3. For a real production deployment (beyond this capstone), evaluate GKE
   Autopilot, which automatically rightsizes node capacity to actual pod
   requests and removes this entire class of manual capacity-planning problem.
4. Review whether all default GKE add-ons enabled by this cluster (network
   policy, managed Prometheus collectors, node-local-dns, etc.) are all
   necessary for a project of this scale, since each adds recurring per-node
   resource overhead.

Teardown Note

This cluster and its supporting resources (VPC, GKE, Jenkins VM, Artifact
Registry images) are running on billed GCP infrastructure. Once evaluation
is complete, run terraform destroy (see terraform/ directory) and delete
the devops-workstation VM to stop all associated billing.
