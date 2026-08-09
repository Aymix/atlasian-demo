output "alb_dns_name" {
  description = "Simulated DNS name of the ALB"
  value       = "${var.project_name}-${var.environment}-alb-${random_id.alb.hex}.eu-west-1.elb.amazonaws.com"
}

output "alb_arn" {
  description = "Simulated ARN of the ALB"
  value       = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:loadbalancer/app/${var.project_name}-${var.environment}-alb/${random_id.alb.hex}"
}

output "alb_zone_id" {
  description = "Simulated Zone ID"
  value       = "Z32O12XQLNTSW2"
}

output "target_group_arn" {
  description = "Simulated target group ARN"
  value       = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:targetgroup/${var.project_name}-${var.environment}-tg/${random_id.alb.hex}"
}

output "alb_security_group_id" {
  description = "Simulated SG ID"
  value       = "sg-${random_id.alb.hex}"
}
