
locals {
  policy_names = {
    developer = data.aws_iam_policy_document.developer.json
    audit     = data.aws_iam_policy_document.readonly.json
    security  = data.aws_iam_policy_document.security.json
  }
}


# for attachment of polices to groups, we can use a for_each loop to iterate over the policy names and attach them to the corresponding groups. Here's how you can do it:
locals {
  group_policy_attachments = {
    developers = "developer"
    readonly   = "audit"
    security   = "security"
  }
}

# developer policy allows developers to have read-only access to EC2, S3, CloudWatch, and other services for development purposes. This policy is designed to enable developers to view resources and monitor their applications without granting them permissions to modify or manage AWS resources.
data "aws_iam_policy_document" "developer" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "s3:ListAllMyBuckets",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]

    resources = ["*"]
  }
}





# auditing only polices
data "aws_iam_policy_document" "readonly" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "s3:Get*",
      "s3:List*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "logs:Describe*",
      "logs:Get*",
      "logs:FilterLogEvents"
    ]

    resources = ["*"]
  }
}



# auditing only security team policies

data "aws_iam_policy_document" "security" {
  statement {
    effect = "Allow"

    actions = [
      "iam:Get*",
      "iam:List*",
      "cloudtrail:Get*",
      "cloudtrail:List*",
      "cloudtrail:LookupEvents",
      "config:Get*",
      "config:List*",
      "config:Describe*",
      "guardduty:Get*",
      "guardduty:List*",
      "securityhub:Get*",
      "securityhub:List*",
      "securityhub:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",

    ]

    resources = ["*"]
  }
}



# Polices attach to groups

resource "aws_iam_policy" "policies_attached" {
  for_each    = local.policy_names
  name        = "${each.key}-policy"
  description = "${each.key} permissions in ${var.env.name} this environment"
  policy      = each.value
}

# attachement of policies to groups
resource "aws_iam_group_policy_attachment" "policies-attach" {
  for_each   = local.group_policy_attachments
  group      = aws_iam_group.groups[each.key].name
  policy_arn = aws_iam_policy.policies_attached[each.value].arn
}



# Mfa enabled policy to ensure that users have MFA enabled for enhanced security. This policy denies access to AWS resources if the user is not authenticated with MFA, except for specific actions that allow users to manage their own MFA devices and obtain session tokens.


data "aws_iam_policy_document" "deny_without_mfa" {
  statement {
    sid    = "DenyActionsWithoutMFA"
    effect = "Deny"

    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken"
    ]

    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}



resource "aws_iam_policy" "mfa" {
  name        = "require-mfa-policy"
  description = "Allows users to manage their own MFA devices"
  policy      = data.aws_iam_policy_document.deny_without_mfa.json
}


resource "aws_iam_group_policy_attachment" "mfa" {
  for_each   = aws_iam_group.groups
  group      = each.value.name
  policy_arn = aws_iam_policy.mfa.arn
}
