resource "aws_ecr_repository" "this" {

  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn == null ? "AES256" : "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = var.tags
}


resource "aws_kms_key" "ecr" {
  count                   = var.kms_key_arn == null ? 1 : 0
  description             = "ECR encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}


resource "aws_ecr_lifecycle_policy" "this" {

  repository = aws_ecr_repository.this.name

  policy = file("${path.module}/lifecycle-policy.json")
}
