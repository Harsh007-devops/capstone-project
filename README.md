# AWS Enterprise DevOps Capstone — GCP Edition

A production-style CI/CD pipeline for a Task Management API, built end-to-end
on GCP: Terraform-provisioned infrastructure, Jenkins CI/CD with security
scanning and multi-stage deployment, Kubernetes + Helm, observability, and
two genuine (not staged) production incidents diagnosed and resolved.

## Architecture

GitHub (source, branching, PR review)
   |
   v
Jenkins (single VM) --- CI: test, lint, build, scan (Trivy)
   |                --- CD: deploy to dev -> test -> [manual approval] -> prod
   v
Artifact Registry (Docker images)
   |
   v
GKE cluster (Terraform-provisioned: VPC, IAM, Secret Manager, 3-node autoscaling pool)
   |
   +-- dev namespace
   +-- test namespace
   +-- prod namespace (LoadBalancer-exposed, Swagger UI reachable in browser)

Cloud Monitoring (CPU/memory alerts) + Cloud Logging (error queries)

## What's in this repo

| Path | Contents |
|---|---|
| app/ | FastAPI Task Management API, unit tests, Dockerfile |
| terraform/ | VPC, GKE cluster, IAM service accounts, Secret Manager, Artifact Registry |
| jenkinsfile | Full CI/CD pipeline: test -> lint -> build -> security scan -> push -> deploy (dev/test/prod with approval gate) |
| k8s/ | Kubernetes Deployment/Service manifests |
| helm/task-api/ | Parameterized Helm chart (image tag, replicas, resource limits) |
| docs/ | Branching strategy, GCP/VM setup guides, and RCA/report documents below |

## Phase-by-phase summary

Phase 1 — Source Control: GitFlow-style branching (main/develop/feature/*),
branch protection rulesets, PR + review workflow used for every single change
in this repo (see commit history: git log --graph).

Phase 2 — CI/CD: Single Jenkinsfile covering CI (install, test, lint, build,
scan, push) and CD (deploy to dev, deploy to test, manual production approval
gate, deploy to prod) — genuine multi-stage pipeline with environment-specific
Kubernetes namespaces.

Phase 3 — Infrastructure as Code: Terraform provisions the VPC (public/private
subnets, Cloud NAT), a GKE Standard cluster with an autoscaling node pool,
least-privilege IAM service accounts (no Owner/Editor on any per-resource
binding), and Secret Manager secrets consumed at runtime.

Phase 4 — Containerization & Kubernetes: Multi-stage, non-root Dockerfile;
Kubernetes Deployment/Service with readiness/liveness probes; a Helm chart
wrapping the same manifests with parameterized values, tested with a real
install to upgrade (revision 1 to 2) cycle.

Phase 5 — Observability: Cloud Monitoring alert policies for CPU and memory
(with a real incident: an initial unscoped policy caused an alert storm,
fixed by adding a container-level filter); Cloud Logging query filtering the
last 24 hours of prod namespace errors.

Phase 6 — DevSecOps: Trivy dependency and container image scanning wired
into the Jenkins pipeline with a fail-on-fixable-critical-vulnerability gate;
a real vulnerability (starlette CVEs) was found and fixed by upgrading
FastAPI, verified with a before and after scan. Snyk was also used for an
independent dependency scan via GitHub import.

Phase 7 — Troubleshooting: Two real (not staged) production incidents,
each with a full RCA — see docs/task14-pipeline-debugging-rca.md and
docs/task15-networking-rca.md.

Phase 8 — Cost Optimization: Real kubectl top utilization data revealed
CPU requests were the scheduling bottleneck despite low actual usage (17-25%
node CPU) — see docs/task16-cost-optimization-report.md for the full
findings and recommendations.

## Notable real incidents (not manufactured for the rubric)

1. Alert storm — an unscoped Cloud Monitoring alert policy fired for every
   container in the cluster, generating 100+ emails. Root-caused to a missing
   container_name filter and fixed live.
2. Task 14 RCA — Jenkins deploy timeout traced to duplicate Helm and kubectl
   deployments competing for CPU on a capacity-constrained cluster.
3. Task 15 RCA — a NetworkPolicy silently had no effect because GKE's
   NetworkPolicy enforcement (Calico) was never enabled at cluster creation;
   even after enabling it, the calico-node DaemonSet couldn't schedule due
   to a missing node label, which itself traced back to the same capacity
   constraints from Task 14.

## Teardown

See docs/teardown-checklist.md for the full, ordered teardown procedure.
Run this before leaving the project idle to stop GCP billing.
