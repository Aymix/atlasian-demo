# Training Scenarios

Hands-on exercises to practice the Atlantis + Terraform + GitHub Actions workflow.

---

## Scenario 1: Basic PR Workflow

**Goal**: Understand the end-to-end PR flow with Atlantis and GHA CI.

### Steps

1. Create a feature branch:
   ```bash
   git checkout -b training/update-vpc-tags
   ```

2. Add a tag to the VPC in `stacks/vpc/main.tf`:
   ```hcl
   resource "aws_vpc" "main" {
     # ... existing config ...
     tags = {
       Name        = "${var.project_name}-${var.environment}-vpc"
       CostCenter  = "engineering"  # ← Add this line
     }
   }
   ```

3. Commit and push:
   ```bash
   git add .
   git commit -m "feat(vpc): add CostCenter tag"
   git push origin training/update-vpc-tags
   ```

4. Open a PR → **Observe**:
   - GHA CI runs format, validate, lint, security checks (only for `vpc` stack)
   - Atlantis auto-plans the `vpc` project
   - Plan output appears as a PR comment

5. Review the plan, then comment: `atlantis apply -p vpc`

---

## Scenario 2: Cross-Stack Changes

**Goal**: See how changes in one stack trigger plans in dependent stacks.

### Steps

1. Create a branch:
   ```bash
   git checkout -b training/add-vpc-output
   ```

2. Add a new output in `stacks/vpc/outputs.tf`:
   ```hcl
   output "vpc_name" {
     description = "Name tag of the VPC"
     value       = aws_vpc.main.tags["Name"]
   }
   ```

3. Use this output in `stacks/alb/main.tf` (add a tag):
   ```hcl
   tags = {
     Name    = "${var.project_name}-${var.environment}-alb"
     VPCName = data.terraform_remote_state.vpc.outputs.vpc_name
   }
   ```

4. Push and open a PR → **Observe**:
   - Both `vpc` and `alb` stacks are detected as changed
   - GHA CI matrix runs checks for both
   - Atlantis plans both projects

---

## Scenario 3: Break Formatting (GHA Catches It)

**Goal**: See how GHA CI catches formatting issues before Atlantis runs.

### Steps

1. Create a branch:
   ```bash
   git checkout -b training/bad-formatting
   ```

2. Intentionally break formatting in `stacks/ecr/main.tf`:
   ```hcl
   resource "aws_ecr_repository" "app" {
       name                 = "${var.project_name}-${var.environment}-app"  # wrong indent (4 spaces instead of 2)
     image_tag_mutability = var.image_tag_mutability
   }
   ```

3. Push and open a PR → **Observe**:
   - GHA CI **fails** on the `fmt` step for `ecr`
   - Atlantis still runs its plan (it's independent)

4. Fix it:
   ```bash
   terraform fmt -recursive stacks/ecr
   git add . && git commit -m "fix: formatting" && git push
   ```

---

## Scenario 4: Add a New Stack

**Goal**: Practice adding a new infrastructure component end-to-end.

### Steps

1. Create a new stack directory:
   ```bash
   mkdir -p stacks/cloudwatch
   ```

2. Create the Terraform files:

   **stacks/cloudwatch/main.tf**
   ```hcl
   terraform {
     required_version = ">= 1.5.0"
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }

   provider "aws" {
     region = var.region
   }

   resource "aws_cloudwatch_dashboard" "main" {
     dashboard_name = "${var.project_name}-${var.environment}"
     dashboard_body = jsonencode({
       widgets = [
         {
           type   = "metric"
           x      = 0
           y      = 0
           width  = 12
           height = 6
           properties = {
             metrics = [["AWS/ECS", "CPUUtilization"]]
             period  = 300
             stat    = "Average"
             region  = var.region
             title   = "ECS CPU Utilization"
           }
         }
       ]
     })
   }
   ```

3. Add the project to `atlantis.yaml`:
   ```yaml
   - name: cloudwatch
     dir: stacks/cloudwatch
     workspace: default
     terraform_version: v1.9.0
     autoplan:
       when_modified: ["*.tf", "*.tfvars"]
       enabled: true
     apply_requirements:
       - approved
       - mergeable
   ```

4. Push and open a PR → The GHA matrix will now include `cloudwatch`

---

## Scenario 5: Atlantis Lock Conflict

**Goal**: Understand Atlantis state locking behavior.

### Steps

1. Open **two PRs** that both modify `stacks/ecs/main.tf`
2. Atlantis plans both PRs
3. Apply one PR → **Observe**: The second PR's plan is now stale
4. Atlantis will require a re-plan on the second PR before allowing apply

---

## Scenario 6: Drift Detection

**Goal**: Understand the drift detection workflow.

### Steps

1. Manually trigger the drift detection workflow:
   ```bash
   gh workflow run "Terraform Drift Detection"
   ```

2. **Observe**: The workflow runs `terraform plan` on all 5 stacks
3. If no resources exist yet, all plans will show "no changes" (no drift)
4. To simulate drift: manually create a tag on a resource in the AWS console, then re-run

---

## Scenario 7: Security Scan Failure

**Goal**: See how tfsec/trivy catches security misconfigurations.

### Steps

1. Create a branch and modify `stacks/alb/main.tf` to remove HTTPS:
   ```hcl
   # Comment out the HTTPS ingress rule in the ALB security group
   # This should trigger a security finding
   ```

2. Push and open a PR → **Observe**:
   - The security scan step flags the missing HTTPS configuration
   - The PR CI fails

---

## Tips

- Use `atlantis plan -p <project>` to plan a specific stack
- Use `atlantis plan` to plan all modified stacks
- Use `atlantis unlock` if a plan lock is stuck
- Run `./scripts/tf-validate.sh <stack>` locally before pushing
- Check `.plans/` directory for saved plan files after running `tf-plan.sh`
