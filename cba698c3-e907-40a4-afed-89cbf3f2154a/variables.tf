variable "aws_region" {
description = "AWS region to create resources in"
type        = string
default     = "us-east-1"
}

variable "vpc_cidr" {
description = "CIDR block for the VPC"
type        = string
default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
description = "CIDR block for the public subnet"
type        = string
default     = "10.0.1.0/24"
}

variable "availability_zone" {
description = "Availability zone to use for the public subnet"
type        = string
default     = "us-east-1a"
}

variable "task_cpu" {
description = "CPU units to assign to the ECS task"
type        = number
default     = 256
}

variable "task_memory" {
description = "Memory to assign to the ECS task"
type        = number
default     = 512
}

variable "app_image" {
description = "Docker image to use for the app container"
type        = string
}

variable "app_port" {
description = "Port the app container will listen on"
type        = number
default     = 80
}

variable "service_count" {
description = "Number of ECS service tasks to run"
type        = number
default     = 2
}