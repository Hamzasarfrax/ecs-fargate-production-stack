output "iam_group_names" {
  description = "IAM group names created in dev."
  value       = module.iam.group_names
}

output "iam_role_arns" {
  description = "IAM role ARNs created in dev."
  value       = module.iam.role_arns
}

output "iam_instance_profile_names" {
  description = "IAM instance profiles created in dev."
  value       = module.iam.instance_profile_names
}
