output "alb_dns_name" {
  value = aws_lb.w1.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
