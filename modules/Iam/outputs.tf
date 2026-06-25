output "groups" {
  value = {
    for key, group in aws_iam_group.groups : key => {
      name = group.name
      arn  = group.arn
    }
  }
}

output "group_names" {
  value = [for group in aws_iam_group.groups : group.name]
}

output "role_arns" {
  value = {
    github_actions = aws_iam_role.github_actions_role.arn
    ecs_execution  = aws_iam_role.ecs_task_execution_role.arn
    terraform      = aws_iam_role.terraform_role.arn
    monitoring     = aws_iam_role.monitoring_role.arn
  }
}

output "instance_profile_names" {
  value = []
}
