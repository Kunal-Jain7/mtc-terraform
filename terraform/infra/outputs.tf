output "execution_role_arn" {
  value = aws_iam_role.ecs-execution-role.arn
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.client-ecs.arn
}

output "public_subnets" {
  value = [for i in aws_subnet.client-pub-sub : i.id]
}

output "app_security_group_id" {
  value = aws_security_group.alb-sec.id
}

output "vpc_id" {
  value = aws_vpc.client-vpc.id
}

output "alb_listener_arn" {
  value = aws_lb_listener.lb-listener.arn
}