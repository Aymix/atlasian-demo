# Atlantis Integration Guide — Complete Feature Reference

> **No AWS needed.** All stacks use `null_resource` + `random` providers.  
> Every `plan` and `apply` produces real state changes locally.

---

## Prerequisites

```bash
brew install terraform               # or: https://developer.hashicorp.com/terraform/install
brew install --cask docker            # or: https://docs.docker.com/get-docker/
brew install ngrok                    # free account at https://ngrok.com
```

---

## PHASE 1 — Push to GitHub

### Step 1: Create repo

GitHub → https://github.com/new → name it `atlasian-demo` → **public** → no README.

### Step 2: Push

```bash
cd ~/Desktop/Training/atlasian
git init && git add . && git commit -m "init: atlantis demo"
git branch -M main
git remote add origin https://github.com/<YOU>/atlasian-demo.git
git push -u origin main
```

### Step 3: Verify locally

```bash
for s in vpc iam ecr alb ecs; do
  terraform -chdir=stacks/$s init -backend=false && terraform -chdir=stacks/$s validate
done
```

---

## PHASE 2 — GitHub PAT

### Step 4: Create token

1. https://github.com/settings/tokens?type=beta → **Generate new token**
2. **Name**: `atlantis-demo` · **Expiration**: 30 days
3. **Repository access**: Only `atlasian-demo`
4. **Permissions**: Contents (RW), Pull requests (RW), Issues (RW), Commit statuses (RW), Webhooks (RW)
5. Copy the token

---

## PHASE 3 — ngrok Tunnel

### Step 5: Start tunnel

```bash
ngrok config add-authtoken <YOUR_NGROK_TOKEN>
ngrok http 4141
```

Copy the `https://xxxx.ngrok-free.app` URL. Keep this terminal open.

---

## PHASE 4 — Start Atlantis

### Step 6: Create `.env`

```bash
cat > .env << 'EOF'
ATLANTIS_GH_USER=<YOUR_GITHUB_USERNAME>
ATLANTIS_GH_TOKEN=<YOUR_PAT>
ATLANTIS_GH_WEBHOOK_SECRET=atlantis-secret-123
ATLANTIS_REPO_ALLOWLIST=github.com/<YOU>/atlasian-demo
ATLANTIS_URL=<YOUR_NGROK_URL>
EOF
```

### Step 7: Start

```bash
docker compose up
```

Verify: open your ngrok URL → Atlantis UI loads.

---

## PHASE 5 — GitHub Webhook

### Step 8: Add webhook

1. `https://github.com/<YOU>/atlasian-demo/settings/hooks` → **Add webhook**
2. **Payload URL**: `https://xxxx.ngrok-free.app/events`
3. **Content type**: `application/json`
4. **Secret**: `atlantis-secret-123`
5. **Events**: Select individual → ✅ Issue comments, ✅ Pull requests, ✅ Pull request reviews, ✅ Pushes
6. Save → wait for ✅ green ping

---

## PHASE 6 — First PR (Autoplan)

### Step 9: Make a change

```bash
git checkout -b feat/first-plan
sed -i '' 's/10.0.0.0\/16/10.1.0.0\/16/' stacks/vpc/variables.tf
git add . && git commit -m "vpc: new CIDR" && git push origin feat/first-plan
```

### Step 10: Open PR on GitHub

**What happens automatically:**
1. GitHub sends `pull_request` webhook → Atlantis
2. Atlantis checks `atlantis.yaml` → `stacks/vpc/*.tf` changed → matches `vpc` project
3. Atlantis runs custom `validated` workflow: `fmt -check` → `init` → `validate` → `plan`
4. Atlantis saves the plan file internally (`~/.atlantis/repos/...`)
5. Atlantis posts the **full plan output** as a PR comment
6. Atlantis adds 👀 reaction to the PR

**You should see a comment like:**
```
Ran Plan for project: vpc dir: stacks/vpc workspace: default
🔍 Running pre-plan checks on vpc
Success! The configuration is valid.

Plan: X to add, X to change, X to destroy.
```

---

## PHASE 7 — All Atlantis Commands

Practice each command by commenting on your open PR.

---

### 📋 PLANNING COMMANDS

#### `atlantis plan`
Plan **all** projects that have changes in this PR.
```
atlantis plan
```

#### `atlantis plan -p <project>`
Plan a **single** project by name (from `atlantis.yaml`).
```
atlantis plan -p vpc
atlantis plan -p ecs
```

#### `atlantis plan -d <dir>`
Plan by **directory path** (no project name needed).
```
atlantis plan -d stacks/vpc
atlantis plan -d stacks/ecs
```

#### `atlantis plan -w <workspace>`
Plan using a specific Terraform **workspace** (for multi-env).
```
atlantis plan -p vpc-staging
```
Or target workspace directly:
```
atlantis plan -d stacks/vpc -w staging
```

#### `atlantis plan -- -var="key=value"`
Pass **extra terraform flags**. Everything after `--` goes to `terraform plan`.
```
atlantis plan -p vpc -- -var="environment=production"
```

#### `atlantis plan -- -target=<resource>`
Plan a **single resource** only.
```
atlantis plan -p vpc -- -target=null_resource.nat_gateway
```

#### `atlantis plan -- -refresh-only`
Plan in **refresh-only mode** — detects drift without proposing changes.
```
atlantis plan -p vpc -- -refresh-only
```

#### `atlantis plan -verbose`
Show the **full terraform output** including init logs (normally hidden).
```
atlantis plan -p vpc -verbose
```

---

### 🚀 APPLY COMMANDS

#### `atlantis apply`
Apply **all** planned projects. Uses the **saved plan file** from `atlantis plan` — not a fresh plan.
```
atlantis apply
```

#### `atlantis apply -p <project>`
Apply a **specific** project.
```
atlantis apply -p vpc
```

#### `atlantis apply -d <dir>`
Apply by **directory**.
```
atlantis apply -d stacks/vpc
```

#### `atlantis apply -w <workspace>`
Apply for a specific **workspace**.
```
atlantis apply -p vpc-staging
```

#### `atlantis apply -auto-merge-disabled`
Apply but **skip auto-merge** even if automerge is enabled.
```
atlantis apply -p vpc -auto-merge-disabled
```

> **How apply uses the plan:**  
> When you `atlantis plan`, Atlantis runs `terraform plan -out=<file>` and stores the binary plan.  
> When you `atlantis apply`, it runs `terraform apply <that-saved-file>` — guaranteeing what you reviewed is what gets applied.  
> If the plan is stale (code changed), Atlantis rejects the apply and asks you to re-plan.

---

### 🔓 LOCK COMMANDS

#### `atlantis unlock`
Release **all locks** held by this PR.
```
atlantis unlock
```

**How locking works:**
- When Atlantis plans a project, it **locks** that project directory
- No other PR can plan/apply the same project until unlocked
- Locks prevent concurrent state modifications
- Locks auto-release when the PR is merged or closed
- You can also unlock via the Atlantis UI → `/locks` page

---

### 📦 STATE COMMANDS

#### `atlantis import -p <project> <address> <id>`
**Import** an existing resource into Terraform state.
```
atlantis import -p ecs null_resource.monitoring my-import-id
```

#### `atlantis state rm -p <project> <address>`
**Remove** a resource from state (does NOT destroy it).
```
atlantis state rm -p ecs null_resource.monitoring
```

---

### ℹ️ INFO COMMANDS

#### `atlantis version`
Show Terraform version being used.
```
atlantis version
```

#### `atlantis help`
List all available commands.
```
atlantis help
```

---

## PHASE 8 — Feature Deep Dives

### Feature 1: Autoplan

**What**: Atlantis automatically plans when a PR is opened or updated.

**Config** (in `atlantis.yaml`):
```yaml
autoplan:
  when_modified: ["*.tf", "*.tfvars", "../../modules/tags/**/*.tf"]
  enabled: true   # set to false to require manual "atlantis plan"
```

**Test it:**
```bash
git checkout -b feat/autoplan-test
echo '# autoplan trigger' >> stacks/vpc/main.tf
git add . && git commit -m "test autoplan" && git push origin feat/autoplan-test
```
Open PR → plan appears automatically within seconds. No comment needed.

---

### Feature 2: Custom Workflows (Pre/Post Hooks)

**What**: Run custom commands before or after plan/apply.

**Config** (in `atlantis.yaml`):
```yaml
workflows:
  validated:
    plan:
      steps:
        - run: echo "PRE-PLAN: checking formatting"
        - run: terraform fmt -check -diff .     # ← pre-plan hook
        - init
        - run: terraform validate               # ← pre-plan hook
        - plan
    apply:
      steps:
        - run: echo "PRE-APPLY: starting"       # ← pre-apply hook
        - apply
        - run: echo "POST-APPLY: done at $(date)"  # ← post-apply hook
```

**Test it:**
The `vpc` project uses the `validated` workflow. Plan it and observe the extra steps in the output:
```
atlantis plan -p vpc
```
You'll see `PRE-PLAN: checking formatting` before the plan output.

---

### Feature 3: Execution Order Groups

**What**: Control the **order** in which projects are applied when using `atlantis apply` (all projects).

**Config**:
```yaml
projects:
  - name: vpc
    execution_order_group: 1    # applied first (foundation)
  - name: alb
    execution_order_group: 2    # applied second (depends on vpc)
  - name: ecs
    execution_order_group: 3    # applied last (depends on everything)
```

**Test it:**
```bash
git checkout -b feat/exec-order
echo '# order test' >> stacks/vpc/main.tf
echo '# order test' >> stacks/alb/main.tf
echo '# order test' >> stacks/ecs/main.tf
git add . && git commit -m "test execution order" && git push origin feat/exec-order
```
Open PR → `atlantis apply` → watch the output: vpc applies first, then alb, then ecs.

---

### Feature 4: Terraform Workspaces (Multi-Environment)

**What**: Use the same Terraform code for multiple environments (dev, staging, prod) via workspaces.

**Config** (already in `atlantis.yaml`):
```yaml
- name: vpc-staging
  dir: stacks/vpc
  workspace: staging
  autoplan:
    enabled: false   # must be triggered manually
```

**Test it:**
```bash
git checkout -b feat/staging
echo '# staging test' >> stacks/vpc/main.tf
git add . && git commit -m "test staging workspace" && git push origin feat/staging
```
Open PR, then comment:
```
atlantis plan -p vpc-staging
```
Atlantis creates a `staging` workspace and plans separately from `default`.

```
atlantis apply -p vpc-staging
```

---

### Feature 5: Repo Locking (Concurrent PR Protection)

**What**: Atlantis locks a project when a plan exists, preventing other PRs from modifying the same project.

**Test it:**

**PR 1:**
```bash
git checkout -b feat/lock-pr1
echo '# PR1 change' >> stacks/ecr/main.tf
git add . && git commit -m "lock test PR1" && git push origin feat/lock-pr1
```
Open PR → Atlantis plans `ecr` → **lock acquired**.

**PR 2** (don't apply PR1):
```bash
git checkout main
git checkout -b feat/lock-pr2
echo '# PR2 change' >> stacks/ecr/main.tf
git add . && git commit -m "lock test PR2" && git push origin feat/lock-pr2
```
Open PR → Atlantis comments: **"This project is locked by PR #X"** ❌

**Fix it** — go to PR1 and comment:
```
atlantis unlock
```
Now PR2 can plan.

**UI alternative**: Go to `https://your-ngrok-url/locks` → click **Unlock** next to the locked project.

---

### Feature 6: Apply Requirements

**What**: Conditions that must be met before `atlantis apply` is allowed.

**Options:**
| Requirement | Meaning |
|-------------|---------|
| `approved` | PR must have at least one approving review |
| `mergeable` | PR must pass all required status checks and have no conflicts |
| `undiverged` | PR branch must not be behind the base branch |

**Config** (in `atlantis.yaml`):
```yaml
apply_requirements:
  - approved      # need code review approval
  - mergeable     # must pass CI checks
  - undiverged    # must be up to date with main
```

**Test it** — set `approved` on a project, then try to apply without approving the PR:
```
atlantis apply -p vpc
```
Atlantis responds: **"Apply rejected: pull request must be approved"**

> For solo training, the current config uses only `mergeable` so you can apply without a reviewer.

---

### Feature 7: Automerge

**What**: Automatically merge the PR after all projects are successfully applied.

**Config** (in `atlantis.yaml`):
```yaml
automerge: true   # set at top level
```

**Test it** — change `automerge: false` to `automerge: true` in `atlantis.yaml`, push, then:
```bash
git checkout -b feat/automerge
echo '# automerge test' >> stacks/iam/main.tf
git add . && git commit -m "test automerge" && git push origin feat/automerge
```
Open PR → `atlantis apply` → PR auto-merges after successful apply.

To skip automerge on a specific apply:
```
atlantis apply -p iam -auto-merge-disabled
```

---

### Feature 8: Parallel Plans

**What**: Plan multiple projects in parallel vs sequentially.

**Config**:
```yaml
parallel_plan: true    # plans run in parallel (faster)
parallel_apply: false  # applies run sequentially (safer)
```

**Test it:**
```bash
git checkout -b feat/parallel
echo '# parallel' >> stacks/vpc/main.tf
echo '# parallel' >> stacks/iam/main.tf
echo '# parallel' >> stacks/ecr/main.tf
git add . && git commit -m "test parallel plan" && git push origin feat/parallel
```
Open PR → all 3 projects plan simultaneously. In the Atlantis logs (`docker compose logs`), you'll see overlapping plan output.

---

### Feature 9: Branch Restrictions

**What**: Only allow Atlantis to operate on PRs from branches matching specific patterns.

**Config** (in `atlantis.yaml`):
```yaml
allowed_regexp_prefixes:
  - dev/
  - feat/
  - fix/
  - ex/
```

**Test it:**
```bash
git checkout -b random-branch
echo '# branch test' >> stacks/vpc/main.tf
git add . && git commit -m "wrong prefix" && git push origin random-branch
```
Open PR → Atlantis **ignores** it (no autoplan, commands won't work).

Now with a valid prefix:
```bash
git checkout -b feat/valid-branch
echo '# branch test' >> stacks/vpc/main.tf
git add . && git commit -m "valid prefix" && git push origin feat/valid-branch
```
Open PR → Atlantis plans normally.

---

### Feature 10: Passing Environment Variables

**What**: Custom workflow steps can access Atlantis-provided environment variables.

**Available env vars in `run` steps:**
| Variable | Value |
|----------|-------|
| `$PROJECT_NAME` | Project name from atlantis.yaml |
| `$WORKSPACE` | Terraform workspace |
| `$DIR` | Relative directory |
| `$PULL_NUM` | PR number |
| `$PULL_AUTHOR` | PR author |
| `$HEAD_BRANCH_NAME` | Source branch |
| `$BASE_BRANCH_NAME` | Target branch |
| `$HEAD_COMMIT` | Latest commit SHA |
| `$BASE_REPO_NAME` | Repository name |
| `$BASE_REPO_OWNER` | Repository owner |
| `$REPO_REL_DIR` | Relative path of the project |
| `$ATLANTIS_TERRAFORM_VERSION` | Terraform version |
| `$COMMENT_ARGS` | Extra args from the comment |

These are used in the `validated` workflow:
```yaml
- run: echo "Planning $PROJECT_NAME in $DIR (PR #$PULL_NUM by $PULL_AUTHOR)"
```

---

### Feature 11: Silence No-Project PRs

**What**: Suppress Atlantis comments when a PR doesn't modify any Terraform projects.

**Config** (in `server-side-repo-config.yaml`):
```yaml
silence_no_projects: true
```

**Test it:**
```bash
git checkout -b feat/docs-only
echo '# docs change' >> README.md
git add . && git commit -m "update readme" && git push origin feat/docs-only
```
With `silence_no_projects: true` → Atlantis stays silent (no comment).
With `false` → Atlantis comments: "No projects were modified."

---

### Feature 12: Checkout Strategy (Merge vs Branch)

**What**: Controls whether Atlantis plans against the branch as-is or against a simulated merge with the base branch.

**Config**:
```yaml
checkout_strategy: merge    # plans what main will look like AFTER merge
# or
checkout_strategy: branch   # plans the branch as-is
```

`merge` is safer — it catches conflicts between your PR and changes already on main.

---

### Feature 13: Delete Source Branch on Merge

**What**: Automatically delete the feature branch after PR merge.

**Config**:
```yaml
delete_source_branch_on_merge: true
```

**Test it:** Set to `true`, apply and merge a PR → the feature branch is automatically deleted.

---

## PHASE 9 — Edge Case Scenarios

### Case 1: Stale Plan

```bash
git checkout -b feat/stale
echo '# v1' >> stacks/vpc/main.tf
git add . && git commit -m "v1" && git push origin feat/stale
```
Open PR → Atlantis plans.

Now push another commit:
```bash
echo '# v2' >> stacks/vpc/main.tf
git add . && git commit -m "v2" && git push origin feat/stale
```
Try: `atlantis apply -p vpc` → **Rejected**: plan is stale, re-plan required.
Fix: `atlantis plan -p vpc` → new plan → `atlantis apply -p vpc` ✅

---

### Case 2: Concurrent Modifications

Open **two PRs** that both modify `stacks/ecs/main.tf`:
1. PR-A plans and locks `ecs`
2. PR-B tries to plan `ecs` → **blocked by lock**
3. Apply PR-A → lock released → PR-B can now plan

---

### Case 3: Plan With No Changes

```bash
git checkout -b feat/no-change
echo '' >> stacks/vpc/main.tf   # whitespace only
git add . && git commit -m "no real change" && git push origin feat/no-change
```
Open PR → Atlantis plans → output shows **"No changes. Infrastructure is up-to-date."**

---

### Case 4: Destroy Resources

```bash
git checkout -b feat/destroy

# Remove a resource from ECS
# (delete the null_resource.monitoring block if it exists)
git add . && git commit -m "remove monitoring" && git push origin feat/destroy
```
Open PR → plan shows **"X to destroy"** → `atlantis apply -p ecs` destroys it.

---

### Case 5: Import → Remove → Re-import

```bash
git checkout -b feat/import-cycle

# 1. Add a resource
cat >> stacks/ecs/main.tf << 'EOF'

resource "null_resource" "cache" {
  triggers = {
    name = "redis-cache"
  }
}
EOF
git add . && git commit -m "add cache" && git push origin feat/import-cycle
```

Open PR:
1. `atlantis plan -p ecs` → shows `1 to add`
2. `atlantis apply -p ecs` → resource created
3. `atlantis state rm -p ecs null_resource.cache` → removed from state
4. `atlantis plan -p ecs` → shows `1 to add` again (it "forgot" about it)
5. `atlantis import -p ecs null_resource.cache cache-123` → re-imported

---

### Case 6: Module Change Triggers All Projects

```bash
git checkout -b feat/module-blast

# Change the shared tags module
sed -i '' 's/ManagedBy   = "terraform"/ManagedBy   = "atlantis"/' modules/tags/main.tf
git add . && git commit -m "update shared tags" && git push origin feat/module-blast
```
Open PR → **ALL 5 projects** autoplan because `atlantis.yaml` watches `../../modules/tags/**/*.tf`.

---

### Case 7: Failed Plan

```bash
git checkout -b feat/bad-syntax

# Introduce a syntax error
echo 'resource "broken" {' >> stacks/ecr/main.tf
git add . && git commit -m "broken syntax" && git push origin feat/bad-syntax
```
Open PR → Atlantis autoplan → **plan fails** → error output in PR comment.
Fix the syntax, push again → Atlantis re-plans automatically.

---

### Case 8: Multiple Workspaces Same PR

```bash
git checkout -b feat/multi-workspace
echo '# workspace test' >> stacks/vpc/main.tf
git add . && git commit -m "workspace test" && git push origin feat/multi-workspace
```
Open PR → autoplan runs for `vpc` (default workspace). Then:
```
atlantis plan -p vpc-staging
```
Now you have **two plans** on the same PR: `vpc` (default) and `vpc-staging` (staging).
Apply them independently:
```
atlantis apply -p vpc
atlantis apply -p vpc-staging
```

---

## PHASE 10 — Atlantis UI

Open your ngrok URL in the browser.

| Page | What It Shows | Action |
|------|---------------|--------|
| `/` | Dashboard with active locks | Overview |
| `/locks` | All locked projects | Click to **unlock** |
| `/jobs/<id>` | Plan/apply output logs | Debug failures |

---

## Quick Reference

| Command | What It Does |
|---------|-------------|
| `atlantis plan` | Plan all modified projects |
| `atlantis plan -p NAME` | Plan specific project |
| `atlantis plan -d DIR` | Plan by directory |
| `atlantis plan -p NAME -w WORKSPACE` | Plan with workspace |
| `atlantis plan -- -var="k=v"` | Plan with extra TF flags |
| `atlantis plan -- -target=RESOURCE` | Plan single resource |
| `atlantis plan -- -refresh-only` | Detect drift only |
| `atlantis plan -verbose` | Plan with full init output |
| `atlantis apply` | Apply all planned projects (in execution order) |
| `atlantis apply -p NAME` | Apply specific project |
| `atlantis apply -p NAME -auto-merge-disabled` | Apply without automerge |
| `atlantis unlock` | Release all locks on this PR |
| `atlantis import -p NAME ADDR ID` | Import resource into state |
| `atlantis state rm -p NAME ADDR` | Remove resource from state |
| `atlantis version` | Show Terraform version |
| `atlantis help` | Show all commands |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Webhook ❌ | Check ngrok running + URL matches + `/events` suffix |
| `"project locked by PR #X"` | `atlantis unlock` on that PR or UI → /locks |
| Plan shows no changes | Ensure push went to PR branch, not main |
| Apply rejected (approval) | Need a review approval, or remove `approved` from `apply_requirements` |
| Apply rejected (stale) | Push changed code → must re-plan first |
| ngrok URL changed | Update webhook URL + `ATLANTIS_URL` in `.env` + restart Atlantis |
| `"not allowed to run on this branch"` | Branch must match `allowed_regexp_prefixes` |
| Custom workflow step fails | Check the `run` command — Atlantis shows the stderr in PR comment |

---

## Cleanup

```bash
docker compose down -v              # stop Atlantis + remove data
# Ctrl+C ngrok terminal
# GitHub → repo Settings → Webhooks → Delete
# GitHub → Settings → Developer settings → Tokens → Delete
```
