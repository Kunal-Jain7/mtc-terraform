resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.client-vpc.id
  tags = {
    Name = "mtc-ecs-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule_alb" {
  for_each          = var.allowed_ips
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "egress_rule_alb" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "-1"
  tags = {
    Name = "allow-all-to-app"
  }
}

resource "aws_security_group" "app" {
  vpc_id = aws_vpc.client-vpc.id
  tags = {
    Name = "mtc-ecs-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule_app" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "-1"

  tags = {
    Name = "allow-all-from-alb"
  }
}

resource "aws_vpc_security_group_egress_rule" "egress_rule_app" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    Name = "allow-all"
  }
}