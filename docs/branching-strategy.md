# Branching Strategy

This repo follows a simplified GitFlow model for the AWS/GCP Enterprise DevOps Capstone.

## Branches

| Branch | Purpose | Deploys to |
|---|---|---|
| `main` | Production-ready code only. Protected. | Prod (GKE `prod` namespace) |
| `develop` | Integration branch. All features merge here first. Protected. | Test (GKE `test` namespace) |
| `feature/*` | One branch per task/feature, e.g. `feature/task-crud-api`, `feature/jenkins-ci-pipeline`. | Dev (GKE `dev` namespace), via CI only |

## Workflow

1. Branch off `develop`:
   ```
   git checkout develop
   git pull origin develop
   git checkout -b feature/<short-description>
   ```
2. Commit work in small, logical commits. Push the branch:
   ```
   git push -u origin feature/<short-description>
   ```
3. Open a Pull Request: `feature/<short-description>` → `develop`.
4. At least one code review required before merge (self-review is acceptable solo,
   but leave real review comments — this is graded on the PR/review evidence).
5. CI (Jenkins) must pass on the PR before it's mergeable.
6. Merge to `develop` → CI/CD auto-deploys to the `test` namespace on GKE.
7. When `develop` is stable, open a PR `develop` → `main`.
8. Merging to `main` triggers the CD pipeline's production stage, gated by a
   **manual approval step** in Jenkins before anything touches the `prod` namespace.

## Branch Protection Rules (GitHub → Settings → Branches)

Applied to both `main` and `develop`:
- Require a pull request before merging (no direct pushes)
- Require at least 1 approving review
- Require status checks to pass before merging (Jenkins CI check)
- Do not allow bypassing the above settings, including for admins (optional, but
  more "production-style" if enabled)

## Commit History Expectation

`git log --graph --oneline --all` should show the pattern:

```
feature/xyz  ---o---o---o
                        \
develop      ------------o------------o (merge)
                                        \
main         --------------------------o (merge)
```

i.e., every commit on `main` arrived via a merge from `develop`, and every commit
on `develop` arrived via a merge from a `feature/*` branch — no direct commits to
either protected branch.
