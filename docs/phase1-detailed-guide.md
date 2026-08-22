# Phase 1: Source Control & Collaboration — Detailed Execution Guide

Run this entire phase from inside your `devops-workstation` VM's SSH session.
Assumes: VM created, `git` installed (steps 1–2 in `manual-tool-install.md`).

Goal for this phase: a GitHub repo with `main`/`develop`/`feature/*` branches,
branch protection, at least one real PR with a review, and commit history that
proves the feature → develop → main flow.

---

## Step 1 — Configure git identity on the VM

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```
This is per-VM, one-time. Without it, commits will fail or show as "unknown".

---

## Step 2 — Bring the sample app onto the VM

Two options:

**Option A — upload the scaffold I gave you.** In the SSH-in-browser window, there's
a gear icon (top right) → "Upload file". Upload `capstone-scaffold-phase1.zip`, then:
```bash
unzip capstone-scaffold-phase1.zip
cd capstone-scaffold
```

**Option B — you already pushed something.** Skip to Step 4 and clone your existing
repo instead of initializing fresh.

---

## Step 3 — Create the GitHub repository

Do this in a **browser tab**, not the SSH session (simplest — no auth token setup needed):

1. Go to github.com → **New repository**
2. Name it (e.g. `devops-capstone-gcp`)
3. **Private** (unless your rubric wants public)
4. **Do NOT** initialize with a README/.gitignore/license — you already have those locally, and it'll cause a merge conflict on first push if GitHub creates its own.
5. Click **Create repository**. Copy the HTTPS URL it shows you, e.g.:
   `https://github.com/<your-username>/devops-capstone-gcp.git`

*(Alternative: `gh repo create` from the SSH session — but that requires `gh auth
login`, which needs a browser anyway for the device code, so the web UI is faster today.)*

---

## Step 4 — Initialize the local repo and make the first commit on `main`

Back in the **SSH session**, inside the `capstone-scaffold` folder:

```bash
git init
git checkout -b main
git add .
git commit -m "Initial commit: FastAPI task management app + branching strategy"
```

Check it worked:
```bash
git log --oneline
git status
```
You should see one commit, and `nothing to commit, working tree clean`.

---

## Step 5 — Connect to GitHub and push `main`

```bash
git remote add origin https://github.com/<your-username>/devops-capstone-gcp.git
git push -u origin main
```

This will prompt for GitHub credentials. GitHub no longer accepts your account
password here — you need a **Personal Access Token (PAT)**:
1. GitHub → your avatar → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
2. Scope: `repo` (full control of private repos)
3. Copy the token **now** (shown once) — paste it as the "password" when git prompts you

Check: refresh the GitHub repo page in your browser — your files should be there.

---

## Step 6 — Create the `develop` branch

```bash
git checkout -b develop
git push -u origin develop
```

Check: GitHub → branch dropdown on your repo → you should see `main` and `develop`.

---

## Step 7 — Turn on branch protection

In the browser, on your GitHub repo:
1. **Settings → Branches → Add branch protection rule**
2. Branch name pattern: `main`
3. Check:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (set to 1)
   - ✅ Require status checks to pass before merging *(leave unchecked for now — you'll come back and check this once Jenkins CI is wired up in Phase 2)*
4. Save
5. Repeat the same rule for `develop`

**Screenshot this page now** — it's one of your required deliverables.

---

## Step 8 — Create a feature branch and make a real change

Back in the SSH session:
```bash
git checkout develop
git checkout -b feature/initial-app-setup
```

Make an actual small edit so the PR has something to review — e.g. add a line to
the README:
```bash
echo "" >> README.md
echo "## Status" >> README.md
echo "Phase 1 complete: branching strategy implemented." >> README.md
```

Commit and push:
```bash
git add README.md
git commit -m "docs: add status section to README"
git push -u origin feature/initial-app-setup
```

---

## Step 9 — Open the Pull Request

In the browser, GitHub will show a yellow banner "Compare & pull request" for your
just-pushed branch. Click it, or go to **Pull requests → New pull request**:
- base: `develop` ← compare: `feature/initial-app-setup`
- Title: `Add status section to README`
- Description: one or two lines on what changed and why
- Create pull request

---

## Step 10 — Perform the code review

Still on the PR page:
1. Go to the **Files changed** tab
2. Click the `+` next to a changed line → leave an actual comment (e.g. "Looks good,
   confirms Phase 1 status clearly.")
3. Go back to **Conversation** tab → **Review changes** (top right) → select
   **Approve** → Submit review

**Screenshot the PR page and the review comment now** — both are required deliverables.

---

## Step 11 — Merge the PR

Click **Merge pull request** → **Confirm merge**. Delete the feature branch when
GitHub offers to (keeps things tidy — you can always recreate a `feature/*` branch
later for the next task).

---

## Step 12 — Promote `develop` → `main`

Once you're happy with what's in `develop` (after Step 11, or after more features
land there later in the day), repeat the same PR pattern one level up:
```bash
git checkout develop
git pull origin develop
```
In the browser: **New pull request**, base: `main` ← compare: `develop`. Review,
approve, merge — same as Steps 9–11.

---

## Step 13 — Capture the commit history proof

Back in the SSH session:
```bash
git checkout main
git pull origin main
git log --graph --oneline --all
```

This should show merge commits flowing `feature/* → develop → main`. Screenshot
this terminal output — it's an explicit required deliverable ("Git commit history
showing feature → develop → main flow").

---

## Phase 1 deliverables checklist

| Item | Where it comes from |
|---|---|
| `branching-strategy.md` | Already in `docs/` from the scaffold |
| Screenshot: Pull Request | Step 9/10 |
| Screenshot: Code review comment | Step 10 |
| Screenshot: Branch protection rules | Step 7 |
| `git log --graph` output showing feature → develop → main | Step 13 |

Once all five are captured, Phase 1 is done — move to Phase 3 (Terraform) next,
per the runbook's build order.
