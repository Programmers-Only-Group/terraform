terraform {
  backend "s3" {
    profile = "irland"
    bucket  = "codebazar-states"
    region  = "eu-west-1"
    key     = "states/core/terraform.tfstate"
  }
}

data "terraform_remote_state" "project-iam" {
  backend = "s3"
  config {
    bucket  = "codebazar-states"
    region  = "eu-west-1"
    profile = "irland"
    key     = "states/core/terraform.tfstate"
  }
}

module "vpc" {
  source = "./vpc"

  owner               = var.owner
  environment_type    = var.environment_type
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_subnet_cidr = var.private_subnet_cidr
  azs                 = var.azs
}

module "sg" {
  source = "./security"

  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source = "./ec2"

  type      = "t3.micro"
  ssh_key   = aws_key_pair.deployer.key_name
  subnet    = module.vpc.public_subnet_1_id
  ec2_sg_id = module.sg.ec2_sg_id
  prefix    = "codebazar"
}

output "instance_profile_name" {
  value = terraform_remote_state.project-iam.instance_profile_ec2
}
