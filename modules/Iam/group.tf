
resource "aws_iam_group" "groups" {
  for_each = var.groups
  name     = each.value
  #   tags = {
  #     Environment = var.env.env
  #     Name        = "${var.env.name}-${each.value}"
  #   }
}
