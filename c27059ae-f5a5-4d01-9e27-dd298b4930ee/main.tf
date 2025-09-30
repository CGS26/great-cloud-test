provider "aws" {
region = "ap-south-1"
}

resource "aws_vpc" "main" {
cidr_block           = "10.0.0.0/16"
enable_dns_hostnames = true

tags = {
Name = "Main VPC"
}
}

resource "aws_subnet" "public" {
vpc_id                  = aws_vpc.main.id
cidr_block              = "10.0.1.0/24"
availability_zone       = "ap-south-1a"
map_public_ip_on_launch = true

tags = {
Name = "Public Subnet"
}
}

resource "aws_internet_gateway" "gw" {
vpc_id = aws_vpc.main.id

tags = {
Name = "Internet Gateway"
}
}

resource "aws_route_table" "public" {
vpc_id = aws_vpc.main.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.gw.id
}

tags = {
Name = "Public Route Table"
}
}

resource "aws_route_table_association" "public" {
subnet_id      = aws_subnet.public.id
route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
name   = "ALB Security Group"
vpc_id = aws_vpc.main.id

ingress {
from_port   = 80
to_port     = 80
protocol    = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port       = 0
to_port         = 0
protocol        = "-1"
cidr_blocks     = ["0.0.0.0/0"]
}

tags = {
Name = "ALB Security Group"
}
}

resource "aws_alb" "main" {
name               = "Main-ALB"
internal           = false
load_balancer_type = "application"
security_groups    = [aws_security_group.alb.id]
subnets            = [aws_subnet.public.id]
}

resource "aws_alb_target_group" "ecs" {
name        = "ECS-Target-Group"
port        = 80
protocol    = "HTTP"
vpc_id      = aws_vpc.main.id
target_type = "ip"
}

resource "aws_alb_listener" "http" {
load_balancer_arn = aws_alb.main.arn
port              = 80
protocol          = "HTTP"

default_action {
type             = "forward"
target_group_arn = aws_alb_target_group.ecs.arn
}
}

resource "aws_ecs_cluster" "main" {
name = "Main-ECS-Cluster"
}

resource "aws_ecs_task_definition" "app" {
family                   = "app-task"
requires_compatibilities = ["FARGATE"]
network_mode             = "awsvpc"
cpu                      = 256
memory                   = 512
container_definitions    = <<DEFINITION
[
{
"name": "app",
"image": "nginx:latest",
"portMappings": [
{
"containerPort": 80,
"hostPort": 80
}
]
}
]
DEFINITION
}

resource "aws_ecs_service" "main" {
name            = "Main-ECS-Service"
cluster         = aws_ecs_cluster.main.id
task_definition = aws_ecs_task_definition.app.arn
desired_count   = 2
launch_type     = "FARGATE"

network_configuration {
subnets          = [aws_subnet.public.id]
security_groups = [aws_security_group.alb.id]
}

load_balancer {
target_group_arn = aws_alb_target_group.ecs.arn
container_name   = "app"
container_port   = 80
}

depends_on = [
aws_alb_listener.http,
aws_ecs_task_definition.app
]
}