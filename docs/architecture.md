# Architecture

## How It All Fits Together

```mermaid
flowchart TB
    DEV["👩‍💻 Developer"] -->|Push branch / Open PR| GH["GitHub Repository"]

    GH -->|Webhook| ATL["🏛️ Atlantis Server"]
    GH -->|Trigger| GHA["⚡ GitHub Actions"]

    subgraph CI ["GitHub Actions CI Pipeline"]
        direction TB
        DETECT["detect-changed-stacks.sh"] --> MATRIX["Matrix Strategy"]
        MATRIX --> FMT["tf-fmt-check.sh"]
        MATRIX --> VAL["tf-validate.sh"]
        MATRIX --> LINT["tf-lint.sh"]
        MATRIX --> SEC["tf-security-scan.sh"]
    end

    subgraph ATLANTIS ["Atlantis PR Workflow"]
        direction TB
        PLAN["atlantis plan"] -->|Comment on PR| REVIEW["👀 Team Review"]
        REVIEW -->|Approve| APPLY["atlantis apply"]
    end

    GHA --> CI
    ATL --> ATLANTIS

    APPLY -->|Deploy| AWS["☁️ AWS"]

    subgraph STACKS ["Terraform Stacks"]
        direction LR
        VPC["vpc"] --> ALB["alb"]
        VPC --> ECS["ecs"]
        IAM["iam"] --> ECS
        ECR["ecr"] --> ECS
        ALB --> ECS
    end

    AWS --> STACKS
```

## Stack Dependency Graph

```mermaid
graph LR
    VPC["🌐 vpc<br/>VPC, Subnets, NAT"] --> ALB["⚖️ alb<br/>ALB, Target Group"]
    VPC --> ECS["🐳 ecs<br/>Cluster, Service"]
    IAM["🔐 iam<br/>Roles, Policies"] --> ECS
    ECR["📦 ecr<br/>Container Registry"] --> ECS
    ALB --> ECS

    style VPC fill:#4a9eff,color:#fff
    style IAM fill:#ff6b6b,color:#fff
    style ECR fill:#feca57,color:#333
    style ALB fill:#48dbfb,color:#333
    style ECS fill:#ff9ff3,color:#333
```

## Flow: What Happens on a PR

1. **Developer** pushes changes to a branch and opens a PR
2. **GitHub** triggers both GitHub Actions and Atlantis via webhooks

### GitHub Actions Path (CI)
3. `detect-changed-stacks.sh` identifies which `stacks/` directories have changes
4. A **matrix job** runs per changed stack in parallel:
   - `tf-fmt-check.sh` — ensures code is properly formatted
   - `tf-validate.sh` — syntax and configuration validation (no AWS creds needed)
   - `tf-lint.sh` — best-practice rules via tflint
   - `tf-security-scan.sh` — security scanning via tfsec/trivy
5. Results appear as **status checks** on the PR

### Atlantis Path (Plan/Apply)
6. Atlantis detects changed projects via `atlantis.yaml` autoplan rules
7. Atlantis runs `terraform plan` for each affected project
8. Plan output is **posted as a comment** on the PR
9. Team members review the plan and the code changes
10. Once the PR has required **approvals** and is **mergeable**, someone comments `atlantis apply`
11. Atlantis runs `terraform apply` and posts the result

### Drift Detection (Scheduled)
- A **weekly cron** job runs `terraform plan` on all stacks against `main`
- If drift is detected (exit code 2), a **GitHub issue** is automatically created

## Remote State Architecture

Each stack has its own state file in a shared S3 bucket:

```
s3://atlasian-demo-tfstate/
├── vpc/terraform.tfstate
├── iam/terraform.tfstate
├── ecr/terraform.tfstate
├── alb/terraform.tfstate
└── ecs/terraform.tfstate
```

Stacks reference each other via `terraform_remote_state` data sources. For example, the `alb` stack reads VPC outputs:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "atlasian-demo-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Usage:
subnets = data.terraform_remote_state.vpc.outputs.public_subnet_ids
```

A DynamoDB table (`atlasian-demo-tflock`) provides state locking.
