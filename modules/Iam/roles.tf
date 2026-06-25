############################################################
# VARIABLES
############################################################



############################################################
# LOCALS
############################################################

locals {

  common_tags = {
    Environment = var.env.env
    ManagedBy   = "terraform"
    Project     = var.name.name
  }

}

############################################################
# GITHUB ACTIONS OIDC PROVIDER
############################################################

resource "aws_iam_openid_connect_provider" "github" {

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

}

############################################################
# GITHUB ACTIONS ASSUME ROLE POLICY
############################################################

data "aws_iam_policy_document" "github_actions_assume_role" {

  statement {

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {

      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]

    }

    condition {

      test = "StringEquals"

      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]

    }

  }

}

############################################################
# GITHUB ACTIONS ROLE
############################################################

resource "aws_iam_role" "github_actions_role" {

  name = "${var.name.name}-github-actions-role"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = local.common_tags

}

############################################################
# GITHUB ACTIONS POLICY
############################################################

data "aws_iam_policy_document" "github_actions_policy" {

  ##########################################################
  # ECS
  ##########################################################

  statement {

    effect = "Allow"

    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeClusters"
    ]

    resources = ["*"]

  }

  ##########################################################
  # ECR
  ##########################################################

  statement {

    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = ["*"]

  }

  ##########################################################
  # CLOUDWATCH LOGS
  ##########################################################

  statement {

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]

  }

  ##########################################################
  # IAM PASS ROLE
  ##########################################################

  statement {

    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.ecs_task_execution_role.arn,
      var.ecs_task_role_arn
    ]

  }

}

resource "aws_iam_policy" "github_actions_policy" {

  name = "${var.name.name}-github-actions-policy"

  policy = data.aws_iam_policy_document.github_actions_policy.json

}

resource "aws_iam_role_policy_attachment" "github_attach" {

  role = aws_iam_role.github_actions_role.name

  policy_arn = aws_iam_policy.github_actions_policy.arn

}

############################################################
# ECS TASK EXECUTION ROLE
############################################################

data "aws_iam_policy_document" "ecs_execution_assume_role" {

  statement {

    actions = ["sts:AssumeRole"]

    principals {

      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]

    }

  }

}

resource "aws_iam_role" "ecs_task_execution_role" {

  name = "${var.name.name}-ecs-task-execution-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json

  tags = local.common_tags

}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {

  role = aws_iam_role.ecs_task_execution_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}

data "aws_iam_policy_document" "ecs_app_policy_document" {

  ##########################################################
  # S3 ACCESS
  ##########################################################

  statement {

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.name.name}-app-bucket",
      "arn:aws:s3:::${var.name.name}-app-bucket/*"
    ]

  }

  ##########################################################
  # CLOUDWATCH
  ##########################################################

  statement {

    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]

  }

}

resource "aws_iam_policy" "ecs_app_policy" {

  name = "${var.name.name}-ecs-app-policy"

  policy = data.aws_iam_policy_document.ecs_app_policy_document.json

}

############################################################
# TERRAFORM ROLE
############################################################

resource "aws_iam_role" "terraform_role" {

  name = "${var.name.name}-terraform-role"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = local.common_tags

}

resource "aws_iam_role_policy_attachment" "terraform_admin_attach" {

  role = aws_iam_role.terraform_role.name

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

}

############################################################
# MONITORING ROLE
############################################################

resource "aws_iam_role" "monitoring_role" {

  name = "${var.name.name}-monitoring-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json

  tags = local.common_tags

}

resource "aws_iam_role_policy_attachment" "monitoring_attach" {

  role = aws_iam_role.monitoring_role.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

}
