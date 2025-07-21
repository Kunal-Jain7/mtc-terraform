locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "client-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "client-ecs-vpc"
  }
}

resource "aws_internet_gateway" "client-igw" {

  tags = {
    Name = "client-ecs-igw"
  }
}

resource "aws_internet_gateway_attachment" "client-igw-attach" {
  vpc_id              = aws_vpc.client-vpc.id
  internet_gateway_id = aws_internet_gateway.client-igw.id
}

resource "aws_route_table" "client-rt" {
  vpc_id = aws_vpc.client-vpc.id
  tags = {
    Name = "client-ecs-rt"
  }
}

resource "aws_route" "client-route" {
  route_table_id         = aws_route_table.client-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.client-igw.id
}

resource "aws_subnet" "client-pub-sub" {
  for_each          = { for i in range(var.num_subnets) : "public${i}" => i }
  vpc_id            = aws_vpc.client-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.client-vpc.cidr_block, 8, each.value)
  availability_zone = local.azs[each.value % length(local.azs)]


  tags = {
    Name = "client-pub-sub1-${each.key}"
  }
}

resource "aws_route_table_association" "rta" {
  for_each       = aws_subnet.client-pub-sub
  subnet_id      = aws_subnet.client-pub-sub[each.key].id
  route_table_id = aws_route_table.client-rt.id
}

resource "aws_lb" "client-loadbal" {
  name               = "client-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for az, id in { for s in aws_subnet.client-pub-sub : s.availability_zone => s.id... } : id[0]]
  security_groups    = [aws_security_group.alb-sec.id]
}

resource "aws_security_group" "alb-sec" {
  vpc_id = aws_vpc.client-vpc.id
  tags = {
    Name = "alb-sec"
  }
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.client-loadbal.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "503"
      message_body = "I'm working a lot, But still no calls"
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb-ingress" {
  for_each          = var.allowed_ips
  security_group_id = aws_security_group.alb-sec.id

  cidr_ipv4   = each.value
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_ecs_cluster" "client-ecs" {
  name = "mts-client-ecs-cluster"
}

resource "aws_iam_role" "ecs-execution-role" {
  name = "ecsExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-execution-role-policy" {
  role       = aws_iam_role.ecs-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}