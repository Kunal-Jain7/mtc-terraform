terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "mtc-kunal"
    workspaces {
      name = "ecs-dev"
    }
  }
}

module "infra" {
  source = "./infra"

  vpc_cidr    = "10.0.0.0/16"
  num_subnets = 2
  allowed_ips = ["0.0.0.0/0"]
}

module "app" {
  source = "./app"

  ecr_repository_name   = "ui"
  image_version         = "1.0.0"
  app_name              = "ui"
  port                  = 80
  execution_role_arn    = module.infra.execution_role_arn
  ecs_cluster_arn       = module.infra.ecs_cluster_arn
  app_security_group_id = module.infra.app_security_group_id
  subnets               = module.infra.public_subnets
  is_public             = true
  vpc_id                = module.infra.vpc_id
  alb_listener_arn      = module.infra.alb_listener_arn
  path_pattern          = "/*"
}