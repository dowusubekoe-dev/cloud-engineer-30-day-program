# Compute module: rebuilds the Day 3 hand-built design under Terraform.
# ALB in the public subnets -> target group -> ASG in the app subnets,
# instances from a launch template carrying the original user data.

resource "aws_lb" "w1" {
  name               = "w1-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.public_security_group_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "w1-alb" }
}

resource "aws_lb_target_group" "app" {
  name        = "w1-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  tags = { Name = "w1-app-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.w1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_launch_template" "app" {
  name          = "app-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_security_group_id]

  user_data = filebase64("${path.module}/userdata.sh")

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "w1-app" }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_desired
  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
