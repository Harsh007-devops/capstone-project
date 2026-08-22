# Manual Tool Installation — Step by Step (No All-in-One Script)

Run these **one command at a time** on the `devops-workstation` VM, via the browser
SSH session (Compute Engine → VM instances → SSH). Check the output of each before
moving to the next. This replaces `scripts/workstation-startup.sh` — use this instead
if you want full control over each step.

---

## 1. Update the package list first

```bash
sudo apt-get update -y
```
Check: no errors in red. This just refreshes what apt knows is available — doesn't
install/upgrade anything yet.

---

## 2. Install basic prerequisites

```bash
sudo apt-get install -y curl gnupg lsb-release apt-transport-https ca-certificates git unzip
```
Check:
```bash
git --version
curl --version
```

---

## 3. Install Docker

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
```
```bash
sudo apt-get update -y
```
```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```
Check:
```bash
sudo docker --version
sudo docker run hello-world
```
Let your user run docker without `sudo` (log out/in or start a new SSH session after this):
```bash
sudo usermod -aG docker $USER
```

---

## 4. Install Terraform

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```
```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```
```bash
sudo apt-get update -y
```
```bash
sudo apt-get install -y terraform
```
Check:
```bash
terraform -version
```

---

## 5. Install kubectl + GKE auth plugin

`gcloud` is already on this VM by default (GCP Debian images ship with it). Just add
the missing components:
```bash
sudo apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin kubectl
```
Check:
```bash
kubectl version --client
gcloud --version
```

---

## 6. Install Helm

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
```
```bash
chmod 700 get_helm.sh
```
```bash
./get_helm.sh
```
Check:
```bash
helm version
```

---

## 7. Install Java (required by Jenkins)

```bash
sudo apt-get install -y fontconfig openjdk-17-jre
```
Check:
```bash
java -version
```

---

## 8. Install Jenkins

```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
```
```bash
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
```
```bash
sudo apt-get update -y
```
```bash
sudo apt-get install -y jenkins
```
Let Jenkins run docker builds later:
```bash
sudo usermod -aG docker jenkins
```
Start it and set it to survive reboots:
```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
```
Check it's actually running:
```bash
sudo systemctl status jenkins
```
(Press `q` to exit the status view.)

---

## 9. Get the Jenkins unlock password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
Keep this handy — you'll paste it into the browser in the next step.

---

## 10. Find your VM's external IP, then open Jenkins in a browser

```bash
curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip"
```
Visit `http://<that-IP>:8080` — paste the password from step 9, install suggested
plugins, create your admin user.

*(If this doesn't load: check the `allow-jenkins` firewall rule exists — see
`docs/gcp-workstation-setup.md` step 2.)*

---

## What you've verified by the end of this list

| Tool | Verify command |
|---|---|
| Docker | `docker --version` |
| Terraform | `terraform -version` |
| kubectl | `kubectl version --client` |
| gcloud | `gcloud --version` |
| Helm | `helm version` |
| Java | `java -version` |
| Jenkins | browser loads `http://<IP>:8080` |

Once every row checks out, you're ready to move to Phase 1 (git/branching) and
Phase 3 (Terraform) — both covered in the main README.
