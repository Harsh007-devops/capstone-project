# AWS Enterprise DevOps Capstone — GCP Edition

Task Management API, deployed via Jenkins CI/CD to GKE, provisioned with Terraform.
See `docs/branching-strategy.md` for the Git workflow.

## What's in this scaffold right now

```
capstone/
├── app/
│   ├── main.py              # FastAPI app: CRUD + /health/live + /health/ready + /metrics
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   └── test_main.py         # 10 unit tests, all passing — this is what Jenkins CI runs
├── docs/
│   └── branching-strategy.md
├── terraform/                # (next: VPC + GKE + IAM + Secret Manager)
├── jenkins/                  # (next: Jenkinsfile CI + CD + multi-stage)
├── k8s/                      # (next: Deployment, Service, probes)
├── helm/                     # (next: Helm chart wrapping k8s/)
├── scripts/                  # (next: teardown script, cost report helper)
└── .gitignore
```

## Exact commands to run tomorrow morning (Phase 1)

```bash
# 1. Confirm app works locally
cd capstone/app
pip install -r requirements-dev.txt
pytest -v          # should show 10 passed
uvicorn main:app --reload --port 8000
# visit http://localhost:8000/docs to sanity check the Swagger UI

# 2. Initialize the repo
cd ..   # back to capstone/
git init
git checkout -b main
git add .
git commit -m "Initial commit: FastAPI task management app + branching strategy"

# 3. Create the GitHub repo (via gh CLI, or do it in the browser)
gh repo create <your-repo-name> --private --source=. --remote=origin
git push -u origin main

# 4. Create develop branch
git checkout -b develop
git push -u origin develop

# 5. In GitHub UI: Settings → Branches → add protection rules for `main` and `develop`
#    (require PR + 1 review; you'll add "require status checks" once Jenkins is wired up)

# 6. Make your first feature branch to prove the workflow
git checkout -b feature/initial-app-setup
# (no code changes needed here, or add a small README tweak)
git push -u origin feature/initial-app-setup
# Open a PR feature/initial-app-setup -> develop on GitHub, leave a review comment,
# merge it. This gives you the PR + review + protection screenshots the rubric wants.
```

**Phase 1 deliverables checklist** (from the rubric):
- [ ] `branching-strategy.md` — done, in `docs/`
- [ ] Screenshot: an open/merged Pull Request
- [ ] Screenshot: a code review comment on that PR
- [ ] Screenshot: branch protection rules page
- [ ] `git log --graph --oneline --all` output showing feature → develop → main flow

## Next up

Once Phase 1 is pushed and screenshotted, move to Terraform (Phase 3) — kick off
`terraform apply` early since GKE provisioning takes 10–15 min, and use that wait
time to write the Dockerfile. See `00_START_HERE_runbook.md` for the full day plan.
 echo ## Status echo Phase 1 complete: branching strategy implemented.
