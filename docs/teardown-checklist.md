Teardown Checklist — Run in This Order

Skipping the order below can leave orphaned GCP Load Balancers that block
Terraform from deleting the VPC.

Step 1 — Delete Kubernetes Services first (releases GCP Load Balancers)
  kubectl delete svc --all -n dev
  kubectl delete svc --all -n test
  kubectl delete svc --all -n prod
  Wait 1-2 minutes for the associated GCP Load Balancer/forwarding rules to
  actually be removed (check: gcloud compute forwarding-rules list)

Step 2 — Uninstall any Helm releases
  helm list --all-namespaces
  helm uninstall <release-name> -n <namespace>   (repeat for any listed)

Step 3 — Destroy Terraform-managed infrastructure
  cd ~/capstone-scaffold/terraform
  terraform destroy
  Type yes when prompted. This removes: GKE cluster, node pool, VPC, subnets,
  Cloud NAT, firewall rules, IAM service accounts, Secret Manager secrets,
  Artifact Registry repo.

Step 4 — Delete the Jenkins/workstation VM
  gcloud compute instances delete instance-20260822-100522 --zone=us-central1-c

Step 5 — Clean up anything created outside Terraform
  gcloud compute firewall-rules delete allow-http --quiet
  gcloud compute firewall-rules delete allow-jenkins-default --quiet
  (list any others: gcloud compute firewall-rules list)

Step 6 — Verify nothing billable remains
  gcloud compute instances list
  gcloud container clusters list
  gcloud compute disks list
  gcloud compute forwarding-rules list
  All of the above should return empty once teardown is complete.

Step 7 — Check GCP Billing Console
  Billing -> Reports -> confirm cost trending to zero over the following day.
