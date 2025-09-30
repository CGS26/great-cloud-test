output "vpc_id" {
value       = aws_vpc.main.id
description = "ID of the created VPC"
}

output "public_subnet_id" {
value       = aws_subnet.public.id
description = "ID of the created public subnet"
}

output "alb_dns_name" {
value       = aws_alb.main.dns_name
description = "DNS name of the created Application Load Balancer"
}

output "ecs_cluster_name" {
value       = aws_ecs_cluster.main.name
description = "Name of the created ECS cluster"
}

output "ecs_service_name" {
value       = aws_ecs_service.main.name
description = "Name of the created ECS service"
}