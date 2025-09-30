variable "vpc_cidr" {
type        = string
default     = "10.0.0.0/16"
description = "CIDR block for the VPC"
}

variable "public_subnet_cidr" {
type        = string
default     = "10.0.1.0/24"
description = "CIDR block for the public subnet"
}

variable "app_container_image" {
type        = string
default     = "nginx:latest"
description = "Docker image for the app container"
}

variable "app_container_port" {
type        = number
default     = 80
description = "Port exposed by the app container"
}

variable "ecs_task_cpu" {
type        = number
default     = 256
description = "CPU units for the ECS task"
}

variable "ecs_task_memory" {
type        = number
default     = 512
description = "Memory (in MB) for the ECS task"
}

variable "ecs_service_desired_count" {
type        = number
default     = 2
description = "Desired count of tasks for the ECS service"
}