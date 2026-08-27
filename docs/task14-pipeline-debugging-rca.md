# Phase 7, Task 14: Pipeline Debugging - Root Cause Analysis

## Failure Summary

**Build:** task-api-ci #8
**Stage failed:** Deploy to Dev
**Error:**
Waiting for deployment "task-api" rollout to finish: 0 of 2 updated replicas are available...
error: timed out waiting for the condition
script returned exit code 1

## Root Cause Analysis

### What happened
The Jenkins pipeline built and pushed a new image successfully, then attempted to
deploy it to the dev namespace via kubectl apply + kubectl rollout status.
The rollout never completed within the 120s timeout, so the stage failed.

### Investigation
kubectl get pods -n dev
Showed 2 pods stuck in "Pending" status

kubectl describe pod <pending-pod-name> -n dev
Events section revealed:
  Warning  FailedScheduling  0/3 nodes are available: 3 Insufficient cpu.
  Normal   NotTriggerScaleUp  Pod didn't trigger scale-up: 1 max node group size reached

### Root cause
The dev namespace had two separate deployment methods both actively managing
pods for the same application:
1. A Helm release (task-api-dev), installed earlier while testing Task 9
2. A plain kubectl apply deployment (task-api), managed by the Jenkins pipeline

Both were running simultaneously, each with their own replica sets. Combined with
similar duplication happening across test/prod namespaces from earlier manual
testing, total pod count exceeded what the 3-node e2-medium cluster (already at
its Terraform-defined max node count) could schedule. The cluster autoscaler tried
to add a 4th node but was blocked by max_node_count = 3 in terraform/gke.tf.

This is a misconfiguration, not a code or infrastructure defect: nothing was
technically wrong with the Terraform, the Jenkinsfile, or the Helm chart individually
- the issue was operational, from running both deployment methods in parallel
against a resource-constrained cluster during iterative testing.

## Fix

helm uninstall task-api-dev -n dev

Removed the redundant Helm-managed release, freeing enough CPU for the
Jenkins-managed pods to schedule.

## Validation

Re-ran the pipeline (build #9). All stages passed, including Deploy to Dev,
Deploy to Test, and Deploy to Prod:

CI pipeline succeeded - image pushed as .../task-api:10

kubectl get pods -n dev confirmed both replicas Running and 1/1 Ready.

## Prevention / Recommendation

For a real production setup, this class of issue is best prevented by:
- Standardizing on one deployment method per namespace (either Helm-only or
  kubectl-manifest-only, not both) - documented in the team's deployment runbook
- Setting resource requests/limits conservatively enough that the node pool has
  headroom for normal iteration, or increasing max_node_count if the workload
  genuinely needs more capacity
- Adding a kubectl get pods --all-namespaces health check as an early pipeline
  stage, so capacity issues surface before a 120-second timeout rather than after
