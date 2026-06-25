# Session Memory — Last Updated: 2026-06-25

## Last Conversation Summary
User asked me to:
1. Find and fix all bugs in the project
2. Rate the project (7.5/10 given)
3. Confirm I don't have persistent memory (setup AGENTS.md + MEMORY.md)

## Bugs Fixed (3)
1. **IAM `ecs_task_role.arn` undeclared** — Added `ecs_task_role_arn` variable to IAM module + passed from all 3 envs
2. **VPC NAT outputs crash when strategy="none"** — Wrapped with `try()`
3. **RDS variable in wrong file** — Moved `enable_cross_region_backup_replication` from main.tf to variables.tf

## User Style
- Hinglish (Hindi + English mix)
- Direct, informal
- Prefers concise answers, no fluff

## Pending / User Wants
- User is evaluating/setting up the project
- May need help with deployment, CI/CD, or filling remaining gaps
