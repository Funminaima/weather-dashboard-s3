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

# create the ecr module 
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
    # depends_on = [ module.ecr ]
    name = format("%v:%v", module.ecr.repository_url, formatdate("YYYY-MM-DD'T'hh-mm-ss", timestamp()))
  build {
context="../"  #this is the path to the local Dockerfile
  }
}

# push the image to the ecr 
resource "docker_registry_image" "this"{
    keep_remotely = false #when a new docker image is added, delete the old one.
    name = docker_image.app_image.name
}