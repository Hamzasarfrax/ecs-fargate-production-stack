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

variable "groups" {
  description = "List of IAM groups to create"
  type        = set(string)
  default     = ["developers", "security", "readonly"]
}






