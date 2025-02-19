terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
   
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  
  }
  # backend "s3" {
  #   bucket = "terraform"
  #   key = "terraform.tfstate"
  #   region = "us-east-1a"
  # }
}

locals{
    container_name="python-weather-dashbaord"
    container_port="5000"
    example="python-weather-dashboard-example"
    ecr_address=format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id,  data.aws_region.this.name)
}

# Configure the AWS Provider
provider "aws" {}
provider "docker"{
    registry_auth {
    address  = local.ecr_address
    username = data.aws_ecr_authorization_token.this.user_name
    password = data.aws_ecr_authorization_token.this.password
  }
}

# create your ECR 
module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "python-weather-dashboard"

#   repository_read_write_access_arns = ["arn:aws:iam::012345678901:role/terraform"]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  
}

# build image locally 
resource "docker_image" "app_image" {
    depends_on = [ module.ecr ]
    name = format("%v:%v", module.ecr.repository_url, formatdate("YYYY-MM-DD'T'hh-mm-ss", timestamp()))
  build {
context="../"  #this is the path to the local Dockerfile
  }
}

# push the image to the ecr 
resource "docker_registry_image" "this" {
  depends_on = [module.ecr] 
    keep_remotely = false #when a new docker image is added, delete the old one.
    name = resource.docker_image.app_image.name
      # name = "${module.ecr.repository_url}:latest"  
}



# create Your ecs cluster 
resource "aws_ecs_cluster" "weather-dashboard-cluster" {
  name= "python-weather-dashboard"
}

#Get your task execution role
data "aws_iam_role" "ecs_task_execution_role" { name = "ecsTaskExecutionRole" }

#create a cloud watch log associated with the ecs
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/python-dashboard-log-group"
}

#create a task defination
# resource "aws_ecs_task_definition" "python-weather-dashboard-task" {
#   family = "python-weather-dashboard-task" # Name of the task definition

#   container_definitions = jsonencode([{
#     name  = local.container_name
#     image = docker_registry_image.this.name

#     portMappings = [{
#       containerPort = local.container_port
#       hostPort      = local.container_port
#     }]

#     logConfiguration = {
#       logDriver = "awslogs"
#       options = {
#         awslogs-region        = "us-east-1"
#         awslogs-group         = aws_cloudwatch_log_group.log_group.name
#         awslogs-stream-prefix = "ecs"
#       }
#     }
#   }])

#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

#   cpu                      = "256"
#   memory                   = "512"
# }

resource "aws_ecs_task_definition" "python-weather-dashboard-task" {
 container_definitions = jsonencode([{
 
  essential = true,
  image = docker_registry_image.this.name,
  name = local.container_name,
  portMappings = [{ containerPort = tonumber(local.container_port) }],
 }])
 cpu = 256
 execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
 family = "python-weather-dashboard-task" 
 memory = 512
 network_mode = "awsvpc"
 requires_compatibilities = ["FARGATE"]
}

# creating application load balancers 
resource "aws_lb" "my-alb" {
  name               = "my-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.egress-only.id, aws_security_group.ingress-http.id]
  subnets            = [aws_subnet.public-1.id,aws_subnet.public-2.id]

  enable_deletion_protection = false

   depends_on = [aws_internet_gateway.igw]
}

resource "aws_alb_listener" "weather-dashboard_http" {
  load_balancer_arn = aws_lb.my-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ip-weather-dashboard.arn
  }
}

resource "aws_lb_target_group" "ip-weather-dashboard" {
  name        = "tg-weather-dashboard"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.python-weather-dashboard-vpc.id
  depends_on = [ aws_lb.my-alb ]
}

#Finally create your service
resource "aws_ecs_service" "python-weather-dashboard-service" {
  name            = "python-weather-dashboard-service"
  cluster         = aws_ecs_cluster.weather-dashboard-cluster.id
  task_definition = aws_ecs_task_definition.python-weather-dashboard-task.arn
  desired_count   = 1
  depends_on      = [aws_ecs_task_definition.python-weather-dashboard-task]
  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ip-weather-dashboard.arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  network_configuration {
    assign_public_ip = false
    security_groups = [aws_security_group.egress-only.id, aws_security_group.ingress.id]
    subnets = [ aws_subnet.private-1.id, aws_subnet.private-2.id]

  }

 
}
output "ecr_module" {
  value = module.ecr
  
}

output "docker-registry_image" {
  value = docker_image.app_image
}

output "alb_url" {
  value = "http://${aws_lb.my-alb.dns_name}"
}




