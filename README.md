# Atlantis + Terraform + GitHub Actions Demo

A training demo showcasing a **multi-stack Terraform** project with **Atlantis** for PR-driven plan/apply and **GitHub Actions** for CI (linting, validation, security scanning).

## Architecture

```
Developer → PR → GitHub
                    ├─→ GitHub Actions (CI)
                    │     ├── detect-changed-stacks.sh → matrix
                    │     ├── tf-fmt-check.sh
                    │     ├── tf-validate.sh
                    │     ├── tf-lint.sh
                    │     └── tf-security-scan.sh
                    │
                    └─→ Atlantis (webhooks)
                          ├── atlantis plan  → comment on PR
                          └── atlantis apply → deploy to AWS
```

## Stacks

| Stack | Resources | Depends On |
|-------|-----------|------------|
| `vpc` | VPC, subnets, NAT, IGW, route tables | — |
| `iam` | ECS execution role, task role, policies | — |
| `ecr` | ECR repository, lifecycle policy | — |
| `alb` | ALB, target group, listener, SG | `vpc` |
| `ecs` | ECS cluster, Fargate service, task def | `vpc`, `iam`, `ecr`, `alb` |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Docker](https://docs.docker.com/get-docker/) (for local Atlantis)
- [tflint](https://github.com/terraform-linters/tflint) (optional)
- AWS account + credentials

Run the setup script to verify:

```bash
chmod +x scripts/setup-local.sh
./scripts/setup-local.sh
```

## Quick Start

### 1. Clone & Setup

```bash
git clone <repo-url>
cd atlasian
./scripts/setup-local.sh
```

### 2. Run Atlantis Locally

```bash
# Edit .env with your GitHub credentials
vim .env

# Start Atlantis
docker compose up
```

Atlantis will be at `http://localhost:4141`.

### 3. GitHub Actions (CI)

The CI pipeline runs automatically on PRs:

1. **Detects** which stacks changed (`detect-changed-stacks.sh`)
2. **Runs in parallel** per changed stack:
   - Format check → `tf-fmt-check.sh`
   - Validate → `tf-validate.sh`
   - Lint → `tf-lint.sh`
   - Security scan → `tf-security-scan.sh`

### 4. Atlantis (Plan/Apply on PR)

On a PR with Terraform changes:

```
# Atlantis auto-plans changed stacks, or manually:
atlantis plan -p vpc
atlantis plan -p ecs

# After review & approval:
atlantis apply -p vpc
atlantis apply -p ecs
```

## Project Structure

```
atlasian/
├── stacks/                          # Terraform stacks (1 state per stack)
│   ├── vpc/                         # Network foundation
│   ├── iam/                         # IAM roles & policies
│   ├── ecr/                         # Container registry
│   ├── alb/                         # Load balancer
│   └── ecs/                         # ECS Fargate service
├── modules/tags/                    # Shared tagging module
├── scripts/                         # Bash scripts (called by GHA)
│   ├── detect-changed-stacks.sh     # Git diff → JSON stack list
│   ├── tf-fmt-check.sh              # terraform fmt -check
│   ├── tf-validate.sh               # terraform validate
│   ├── tf-lint.sh                   # tflint
│   ├── tf-security-scan.sh          # tfsec / trivy
│   ├── tf-plan.sh                   # terraform plan
│   └── setup-local.sh               # Local dev setup
├── .github/workflows/               # GitHub Actions
│   ├── terraform-ci.yml             # PR CI: lint, validate, scan
│   ├── terraform-plan.yml           # Plan per changed stack
│   └── terraform-drift.yml          # Weekly drift detection
├── atlantis.yaml                    # Repo-level Atlantis config
├── server-side-repo-config.yaml     # Server-side Atlantis config
├── docker-compose.yml               # Local Atlantis server
├── .tflint.hcl                      # Shared tflint config
└── docs/
    ├── architecture.md              # Diagrams & flow explanation
    └── training-scenarios.md        # Hands-on exercises
```

## Scripts → Workflows Mapping

| Script | Used By | Purpose |
|--------|---------|---------|
| `detect-changed-stacks.sh` | `terraform-ci.yml`, `terraform-plan.yml` | Git diff to find changed stacks |
| `tf-fmt-check.sh` | `terraform-ci.yml` | Format compliance |
| `tf-validate.sh` | `terraform-ci.yml` | Syntax/config validation |
| `tf-lint.sh` | `terraform-ci.yml` | Best-practice linting |
| `tf-security-scan.sh` | `terraform-ci.yml` | Security scanning |
| `tf-plan.sh` | `terraform-plan.yml`, `terraform-drift.yml` | Full terraform plan |

## Training

See [docs/training-scenarios.md](docs/training-scenarios.md) for hands-on exercises.

## License

MIT
