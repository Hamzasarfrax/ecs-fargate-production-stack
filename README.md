# Portfolio AWS Platform

Production-style AWS infrastructure for a containerized application platform, built with Terraform and reusable AWS modules. The project is designed to show how a real company can run an application securely across `dev`, `stage`, and `prod` with CloudFront, private networking, ECS Fargate, ALB, ECR, RDS, Redis, IAM, CloudWatch monitoring, and cost-aware VPC endpoint design.

The main goal is not only to create resources, but to show an engineering mindset: security first, cost control, automation, scalability, availability, fault tolerance, and clean module ownership.

## Project Mindset

This project was built like an internal cloud platform, not a one-time demo. Each major AWS area is separated into a Terraform module so the infrastructure can be reused, reviewed, upgraded, and promoted from dev to stage to production.

Key design goals:

- Keep application workloads private.
- Expose traffic only through a controlled ALB entry point.
- Reduce fixed networking cost in dev by replacing NAT dependency with VPC endpoints.
- Use autoscaling and managed services instead of manually managed servers.
- Add monitoring, alarms, and dashboards from day one.
- Keep production controls configurable without making dev unnecessarily expensive.

## Architecture Overview

Traffic enters through a public Application Load Balancer. ECS Fargate tasks run inside private subnets with no public IP address. RDS and Redis are also private and only accept traffic from the ECS security group.

```text
Internet
   |
   v
CloudFront Edge Distribution
   |
   v
Application Load Balancer (public subnets)
   |
   v
ECS Fargate Service (private subnets)
   |
   +--> RDS MySQL (private)
   |
   +--> Redis / ElastiCache (private)
   |
   +--> AWS services through VPC endpoints
```

## Environments

| Environment | Path       | Purpose                                                               |
| ----------- | ---------- | --------------------------------------------------------------------- |
| Dev         | `env/dev`  | Low-cost development. NAT disabled by default and WAF off.            |
| Stage       | `env/stag` | Pre-production validation. WAF enabled for closer production testing. |
| Prod        | `env/prod` | Production profile. WAF and ALB deletion protection enabled.          |

## Modules

| Module                  | Responsibility                                                                                  |
| ----------------------- | ----------------------------------------------------------------------------------------------- |
| `modules/Vpc`           | VPC, public/private subnets, route tables, NAT strategy, VPC endpoints.                         |
| `modules/Cloudfront`    | Edge distribution in front of ALB, HTTPS redirect, optional aliases, optional access logs.      |
| `modules/Load-balancer` | ALB, target group, HTTP/optional HTTPS listener, optional WAF, optional access logs.            |
| `modules/Ecs`           | ECS Fargate service, task definition, CloudWatch logs, autoscaling, deployment circuit breaker. |
| `modules/Ecr`           | Container registry, image scanning, immutable tags, lifecycle policy.                           |
| `modules/Rds`           | Private MySQL RDS, encryption, managed password, Redis cache, security groups.                  |
| `modules/Iam`           | IAM groups, MFA guardrail, GitHub Actions OIDC role, ECS task roles.                            |
| `modules/Monitoring`    | CloudWatch alarms, dashboard, SNS email alerts, root login alert.                               |

## Security Highlights

- ECS tasks run in private subnets with `assign_public_ip = false`.
- RDS and Redis are private and only allow inbound traffic from the ECS security group.
- ALB is the only public entry point.
- CloudFront can sit in front of ALB to provide edge entry, HTTPS redirect, and future CDN/WAF controls.
- IAM roles are separated for ECS execution, ECS task permissions, GitHub Actions, Terraform, and monitoring.
- ECR scan-on-push is enabled for container vulnerability visibility.
- RDS storage encryption and managed master password are used.
- MFA guardrail policy is included for IAM groups.
- Root account login alert is configured through EventBridge and SNS.

## Cost Optimization

The VPC module supports `nat_gateway_strategy = "none"` for dev. Instead of paying for an always-on NAT Gateway, private workloads can use VPC endpoints for common AWS services:

- S3 gateway endpoint
- DynamoDB gateway endpoint
- ECR API endpoint
- ECR Docker endpoint
- CloudWatch Logs endpoint
- Secrets Manager endpoint
- SSM, SSM Messages, and EC2 Messages endpoints

This design keeps private subnets useful while reducing fixed monthly cost in development environments.

## Scalability And Performance

- ECS Fargate removes EC2 server management.
- ECS autoscaling adjusts service capacity based on CPU and memory.
- Redis is included as a cache layer for hot reads and reduced RDS load.
- ALB health checks route traffic only to healthy targets.
- CloudWatch alarms detect CPU, memory, ALB 5XX, latency, and RDS CPU issues.

## Availability And Fault Tolerance

- Subnets are spread across multiple Availability Zones.
- ALB distributes traffic across healthy ECS tasks.
- ECS deployment circuit breaker can roll back unhealthy deployments.
- Production RDS settings are stricter than dev, including deletion protection and final snapshot behavior.
- Stage/prod can enable WAF and ALB deletion protection while dev remains lightweight.

## Automation

Terraform manages infrastructure as code across all environments. The IAM module also includes a GitHub Actions OIDC role design so CI/CD can be added without long-lived AWS access keys.

Recommended future pipeline:

```text
Pull Request
  -> terraform fmt
  -> terraform validate
  -> security scan
  -> terraform plan
  -> approval
  -> terraform apply
```

## Local Validation

```powershell
cd env/dev
terraform init -backend=false
terraform validate
terraform plan
```

For real AWS remote state, update each environment `provider.tf` backend with your actual S3 bucket, DynamoDB lock table, and KMS key alias.

## LocalStack Testing

The `test` folder is a local-only Terraform playground for practicing AWS-style workflows without creating real cloud resources. It uses fake AWS credentials and points provider endpoints to `http://localhost:4566`.

```powershell
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 localstack/localstack

cd test
terraform init
terraform validate
terraform plan
terraform apply
```

The local test includes S3, EC2, and a CloudFront-style Terraform distribution. CloudFront local execution depends on the LocalStack version/edition available on your machine, so keep this as a learning and validation path while `env/dev`, `env/stag`, and `env/prod` remain the real AWS environments.

## Important Variables

- `aws_region`: AWS region, default `us-east-1`.
- `project_name`: Prefix used for named resources.
- `environment`: `dev`, `stage`, or `prod`.
- `nat_gateway_strategy`: `none`, `single`, or `one_per_az`.
- `certificate_arn`: ACM certificate ARN. If null, ALB serves HTTP only.
- `alb_access_logs_bucket`: Existing S3 bucket for ALB logs. If null, access logging is disabled.
- `alert_email`: SNS subscription email for alarms.

## What Makes This Advanced

- Multi-environment structure instead of a single flat Terraform file.
- Reusable modules with clear boundaries.
- Private ECS, RDS, and Redis architecture.
- VPC endpoints used as a NAT cost-reduction strategy.
- CloudFront module in front of ALB for edge delivery and production-style traffic flow.
- Optional production-grade controls like WAF, HTTPS, access logs, deletion protection, and backup replication.
- ECS autoscaling and deployment circuit breaker.
- CloudWatch alarms and operational dashboard.
- IAM guardrails and GitHub OIDC-ready automation design.

## Next Developer Notes

Before applying this in a real AWS account:

- Replace backend bucket, DynamoDB table, and KMS alias in `provider.tf`.
- Set a real `alert_email`.
- Provide `certificate_arn` for HTTPS.
- Provide an existing S3 bucket name in `alb_access_logs_bucket` if ALB logs are required.
- Replace the placeholder `nginx:latest` image with an application image from ECR.
- Run `terraform plan` carefully for each environment before `apply`.

## Portfolio Talking Points

- I designed a secure AWS platform where public traffic enters through ALB and application workloads stay private.
- I optimized dev cost by avoiding NAT Gateway and using VPC endpoints for private AWS service access.
- I used Terraform modules to make the infrastructure reusable and easier for teams to maintain.
- I added autoscaling, monitoring, alarms, and deployment rollback behavior to make the platform production-oriented.
- I separated dev, stage, and prod so changes can be tested before reaching production.
