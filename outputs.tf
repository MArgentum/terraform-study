output "alb_dns_name" {
    value       = aws_lb.my_load_balancer.dns_name
    description = "The public IP address of the load balancer"
}
