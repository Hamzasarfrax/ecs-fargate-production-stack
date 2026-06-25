variable "env" {
  description = "Environment configuration"
  type = object({
    name    = string
    env     = string
    tagname = string
  })

  default = {
    name    = "my-app"
    env     = "dev"
    tagname = "dev-tag"
  }
}

variable "name" {
  description = "Project naming context."
  type = object({
    name = string
  })
  default = {
    name = "my-app"
  }
}

variable "groups" {
  description = "List of IAM groups to create"
  type        = set(string)
  default     = ["developers", "security", "readonly"]
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role (created outside this module)"
  type        = string
}





