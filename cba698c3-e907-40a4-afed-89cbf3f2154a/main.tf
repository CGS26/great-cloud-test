provider "aws" {
region = var.aws_region
}

resource "aws_vpc" "main" {
cidr_block           = var.vpc_cidr
enable_dns_support   = true
enable_dns_hostnames = true

tags = {
Name = "Main VPC"
}
}

resource "aws_subnet" "public" {
vpc_id                  = aws_vpc.main.id
cidr_block              = var.public_subnet_cidr
availability_zone       = var.availability_zone
map_public_ip_on_launch = true

tags = {
Name = "Public Subnet"
}
}

resource "aws_internet_gateway" "main" {
vpc_id = aws_vpc.main.id

tags = {
Name = "Main IGW"
}
}

resource "aws_route_table" "public" {
vpc_id = aws_vpc.main.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.main.id
}

tags = {
Name = "Public Route Table"
}
}

resource "aws_route_table_association" "public" {
subnet_id      = aws_subnet.public.id
route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_tasks" {
name   = "ECS Tasks Security Group"
vpc_id = aws_vpc.main.id

ingress {
from_port       = 0
to_port         = 0
protocol        = "-1"
cidr_blocks     = ["0.0.0.0/0"]
}

egress {
from_port       = 0
to_port         = 0
protocol        = "-1"
cidr_blocks     = ["0.0.0.0/0"]
}

tags = {
Name = "ECS Tasks Security Group"
}
}

resource "aws_ecs_cluster" "main" {
name = "Main ECS Cluster"
}

resource "aws_ecs_task_definition" "app" {
family                   = "app-task"
requires_compatibilities = ["FARGATE"]
network_mode             = "awsvpc"
cpu                      = var.task_cpu
memory                   = var.task_memory
execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn

container_definitions = <<DEFINITION
[
{
"name": "app",
"image": "${var.app_image}",
"portMappings": [
{
"containerPort": ${var.app_port},
"hostPort": ${var.app_port}
}
],
"essential": true,
"environment": [],
"mountPoints": [],
"volumesFrom": []
}
]
DEFINITION
}

resource "aws_ecs_service" "app" {
name            = "app-service"
cluster         = aws_ecs_cluster.main.id
task_definition = aws_ecs_task_definition.app.arn
desired_count   = var.service_count
launch_type     = "FARGATE"

network_configuration {
subnets          = [aws_subnet.public.id]
security_groups  = [aws_security_group.ecs_tasks.id]
assign_public_ip = true
}

load_balancer {
target_group_arn = aws_lb_target_group.app.arn
container_name   = "app"
container_port   = var.app_port
}

depends_on = [aws_lb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role_policy]
}

resource "aws_lb" "main" {
name               = "Main-LB"
internal           = false
load_balancer_type = "application"
security_groups    = [aws_security_group.lb.id]
subnets            = [aws_subnet.public.id]
}

resource "aws_lb_listener" "front_end" {
load_balancer_arn = aws_lb.main.arn
port              = 80
protocol          = "HTTP"

default_action {
type             = "forward"
target_group_arn = aws_lb_target_group.app.arn
}
}

resource "aws_lb_target_group" "app" {
name        = "App-TG"
port        = var.app_port
protocol    = "HTTP"
vpc_id      = aws_vpc.main.id
target_type = "ip"
}

resource "aws_iam_role" "ecs_task_execution_role" {
name = "ecs-task-execution-role"

assume_role_policy = <<POLICY
{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Principal": {
"Service": "ecs-tasks.amazonaws.com"
},
"Action": "sts:AssumeRole"
}
]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
policy_arn       = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
role             = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_security_group" "lb" {
name   = "Load Balancer Security Group"
vpc_id = aws_vpc.main.id

ingress {
from_port       = 80
to_port         = 80
protocol        = "tcp"
cidr_blocks     = ["0.0.0.0/0"]
}

egress {
from_port       = 0
to_port         = 0
protocol        = "-1"
cidr_blocks     = ["0.0.0.0/0"]
}

tags = {
Name = "Load Balancer Security Group"
}
}