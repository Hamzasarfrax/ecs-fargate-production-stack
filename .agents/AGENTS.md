# Project Context

## What is this?
Terraform AWS infrastructure for a containerized PHP/Laravel app (ECS Fargate + ALB + RDS + ElastiCache + CloudFront).

## Structure
- `backend/` — S3 + DynamoDB remote state
- `env/{dev,stag,prod}/` — per-environment config (main.tf orchestrates all modules)
- `modules/{Vpc,Load-balancer,Ecs,Ecr,Rds,Iam,Cloudfront,Monitoring}/` — reusable modules
- `Dockerfile`, `docker/` — nginx + PHP-FPM + Supervisor

## Key conventions
- Private subnets + VPC endpoints (no NAT in dev)
- Blue/green CodeDeploy for ECS (optional)
- WAF on stage/prod only
- `nat_gateway_strategy` = "single" | "one_per_az" | "none"
- IAM OIDC for GitHub Actions
- RDS cross-region backup replication for prod

## Known bugs fixed
1. IAM module `roles.tf:169` referenced `aws_iam_role.ecs_task_role.arn` but role was moved to env files — fixed by adding `ecs_task_role_arn` variable
2. VPC outputs crashed when `nat_gateway_strategy="none"` — fixed with `try()`
3. RDS variable `enable_cross_region_backup_replication` was in `main.tf` instead of `variables.tf` — moved

## Remaining gaps
- No `tfvars` files (uses all defaults)
- No tflint/tfsec/checkov in CI
- No tests (Terratest etc.)
- Trivy scan runs but doesn't fail on high/critical
- `continue-on-error` on `terraform fmt -check` in CI
- No PHP source in repo (Dockerfile runs `composer install` / `artisan optimize`)
