variable "ecr_repository_name" {
  type = string
}

variable "image_version" {
  type = string
}

variable "app_name" {
  type = string
}

variable "port" {
  type = number
}

variable "execution_role_arn" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}

variable "app_security_group_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "is_public" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type = string
}

variable "alb_listener_arn" {
  type = string
}

variable "path_pattern" {
  type    = string
  default = "/*"
}