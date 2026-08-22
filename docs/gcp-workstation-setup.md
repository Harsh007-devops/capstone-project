# GCP Workstation Setup — Do Everything on GCP, Nothing Local

Since you're running this entire project from GCP itself (not your laptop), here's
the exact flow for tomorrow morning. You will need a browser and a GCP account —
nothing else installed anywhere.

## Step 1 — Create the project (do this from Cloud Console in browser, or Cloud Shell)

GCP gives you a free built-in terminal called **Cloud Shell** (top-right `>_` icon in
console.cloud.google.com) — no VM needed just to run the two commands below:

```bash
gcloud projects create devops-capstone-<yourname> --set-as-default
gcloud config set project devops-capstone-<yourname>
# link billing (must be done once, in the browser: Billing -> Link a billing account)

gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  compute.googleapis.com
```

## Step 2 — Create the workstation VM

Still from Cloud Shell (or the Console UI if you prefer clicking):

```bash
gcloud compute instances create devops-workstation \
  --zone=us-central1-a \
  --machine-type=e2-standard-2 \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=50GB \
  --tags=jenkins,workstation \
  --scopes=cloud-platform \
  --metadata-from-file=startup-script=workstation-startup.sh
```

> Upload `workstation-startup.sh` (from `scripts/` in your project) to Cloud Shell first —
> drag-and-drop into the Cloud Shell file pane, or use the Cloud Shell Editor's upload button.
> Cloud Shell's working directory is where the command above should run from.

Open the firewall so you can reach Jenkins later:

```bash
gcloud compute firewall-rules create allow-jenkins \
  --allow=tcp:8080 \
  --target-tags=jenkins \
  --source-ranges=0.0.0.0/0
```

The startup script takes **3–5 minutes** to finish installing everything (Docker,
Terraform, kubectl, Helm, Jenkins). Grab a coffee.

## Step 3 — SSH into the VM (browser-based, zero local setup)

Go to **Compute Engine → VM instances** in the Console, find `devops-workstation`,
click the **SSH** button. This opens a full terminal in your browser, running on the
VM itself.

Verify the startup script finished:
```bash
sudo tail -50 /var/log/startup-script.log
docker --version
terraform -version
kubectl version --client
helm version
```

If any are missing, the startup script may still be running — check with:
```bash
sudo journalctl -u google-startup-scripts.service -f
```

## Step 4 — Clone/push your project from this VM

Since your GitHub repo needs to exist too, do it from here:
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
gh auth login   # if gh CLI isn't present: sudo apt-get install -y gh
```
Then follow the same `git init` / branching steps from the project README — just run
them **inside this SSH session** instead of a local terminal.

## Step 5 — Access Jenkins

Jenkins is already installed and running on this same VM (port 8080).

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Find the VM's external IP:
```bash
gcloud compute instances describe devops-workstation \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

Visit `http://<EXTERNAL_IP>:8080` in your browser, paste the initial admin password,
install suggested plugins, create your admin user.

## Step 6 — Everything else runs from this same SSH session

Terraform apply, Docker builds, kubectl commands, Helm installs — all of it happens
in this one browser SSH tab into `devops-workstation`. One machine, one session,
nothing local.

## End of day teardown (important — this VM bills by the hour)

```bash
# from Cloud Shell or your local browser console, NOT from inside the workstation
gcloud compute instances delete devops-workstation --zone=us-central1-a --quiet
gcloud compute firewall-rules delete allow-jenkins --quiet
# plus: terraform destroy for the GKE cluster (run this from inside the workstation
# BEFORE deleting the workstation itself, or you'll lose the terraform state)
```

**Order matters at teardown:** `terraform destroy` (GKE, from inside the VM) →
then delete the workstation VM → then double check GCP Console → Billing for
anything still running.
