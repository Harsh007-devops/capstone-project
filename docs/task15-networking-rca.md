Phase 7, Task 15: Kubernetes Networking Issue - Root Cause Analysis

Issue Description

A Deployment (task-api) in the dev namespace was unable to reach external
services after a NetworkPolicy named deny-all-egress was applied. The pod's
outbound HTTPS request to https://www.google.com failed.

Diagnosis Steps

Step 1 - Confirmed baseline connectivity worked before applying the policy:
  kubectl exec -it deploy/task-api -n dev -- python3 -c "..."
  Result: 200 OK

Step 2 - Applied the NetworkPolicy:
  kubectl apply -f k8s/deny-egress-policy.yaml -n dev
  Result: networkpolicy.networking.k8s.io/deny-all-egress created

Step 3 - Re-tested connectivity, expecting it to fail:
  Result: still returned 200 OK - the policy had NO effect.

Step 4 - Checked whether NetworkPolicy enforcement was even enabled on the cluster:
  gcloud container clusters describe capstone-gke --zone us-central1-a --format="get(networkPolicy)"
  Result: empty output - enforcement was never enabled on this GKE cluster.
  A NetworkPolicy object can exist in the API without any effect if no CNI
  component (e.g. Calico) is present to enforce it.

Step 5 - Enabled NetworkPolicy enforcement:
  gcloud container clusters update capstone-gke --zone us-central1-a --update-addons=NetworkPolicy=ENABLED
  gcloud container clusters update capstone-gke --zone us-central1-a --enable-network-policy

Step 6 - Re-tested again, still got 200 OK. Deeper investigation:
  kubectl get daemonset -n kube-system | grep calico
  Result: calico-node DaemonSet showed DESIRED=0, CURRENT=0, READY=0

Step 7 - Found the actual root cause: the calico-node DaemonSet requires nodes
  to carry the label projectcalico.org/ds-ready=true. GKE's documentation
  describes enabling NetworkPolicy as triggering "a rolling update of all
  cluster nodes" to add this label automatically - but node age remained
  unchanged (16h, not recreated), meaning the rolling update did not actually
  happen. This is consistent with the cluster's ongoing CPU capacity
  constraints (see Task 14 RCA) preventing a safe node-by-node replacement.
  With no nodes carrying the required label, the enforcement DaemonSet had
  zero eligible nodes and could not schedule anywhere - so despite the
  cluster-level "NetworkPolicy: enabled=True" flag, nothing was actually
  enforcing policies.

Root Cause

Two compounding issues:
1. NetworkPolicy enforcement (Calico) was not enabled when the cluster was
   originally provisioned via Terraform.
2. After enabling it via gcloud, the automatic node-label rollout that Calico's
   DaemonSet depends on did not complete, likely due to the cluster already
   running near its CPU capacity limit, preventing GKE from safely rotating
   nodes.

Fix

  kubectl label nodes --all projectcalico.org/ds-ready=true

Manually applied the label GKE's automatic rollout should have set. This let
the calico-node DaemonSet schedule one pod per node (confirmed 3/3 Running).

Validation

Re-tested the deny-all-egress policy after the fix:
  kubectl exec -it deploy/task-api -n dev -- python3 -c "..."
  Result: socket.gaierror: Temporary failure in name resolution
  (DNS resolution itself was blocked - proof the policy was now genuinely
  enforced, since it could not even resolve the hostname to attempt a
  connection.)

Removed the test policy and confirmed connectivity was restored:
  kubectl delete networkpolicy deny-all-egress -n dev
  kubectl exec -it deploy/task-api -n dev -- python3 -c "..."
  Result: 200 OK

Prevention / Recommendation

- Enable the NetworkPolicy add-on (google_container_cluster.primary.network_policy
  in Terraform) at cluster creation time rather than retrofitting it later,
  avoiding the incomplete-rollout scenario entirely.
- After any addon change that requires a node rolling update, explicitly verify
  node age/recreation rather than trusting the "Updated" success message alone -
  as seen here, the update command can report success while the underlying
  rolling update silently does not complete due to resource constraints.
- Address the cluster's recurring CPU capacity constraints (see Task 14 and
  Task 8 cost-optimization notes) since they were the underlying reason the
  automatic node rotation could not proceed safely.
