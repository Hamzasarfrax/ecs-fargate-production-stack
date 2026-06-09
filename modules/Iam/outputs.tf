output "groups" {
  value = {
    for key, group in aws_iam_group.groups : key => {
      name = group.name
      arn  = group.arn
    }
  }
}
