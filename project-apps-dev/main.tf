
terraform {
  backend "s3" {
    profile = "default"
    bucket  = "programmers-only-states"
    region  = "eu-central-1"
    key     = "states/apps/terraform.tfstate"
  }
}

data "terraform_remote_state" "project-iam" {
  backend = "s3"
  config = {
    bucket = "programmers-only-states"
    region = "eu-central-1"
    key    = "states/iam/terraform.tfstate"
  }
}

data "terraform_remote_state" "project-core" {
  backend = "s3"
  config = {
    bucket = "programmers-only-states"
    region = "eu-central-1"
    key    = "states/core/terraform.tfstate"
  }
}

resource "aws_kms_key" "programmers_only" {
  description             = "Programmers Only Key"
}

module "sg" {
  source = "./security"

  vpc_id = data.terraform_remote_state.project-core.outputs.vpc_common_id
}

module "lambda" {
  source = "./lambda"

  iam_for_aws_costs_lambda_arn = data.terraform_remote_state.project-iam.outputs.iam_aws_costs_lambda_arn
  iam_for_asg_manager_lambda_arn = data.terraform_remote_state.project-iam.outputs.iam_asg_manager_lambda_arn
}

module "ProgrammersOnly" {
  source = "./ProgrammersOnly"

  prefix               = "programmers-only"
  key_name             = data.terraform_remote_state.project-core.outputs.key_name
  iam_instance_profile = data.terraform_remote_state.project-iam.outputs.instance_profile_ec2
  asg_role             = data.terraform_remote_state.project-iam.outputs.allow_posting_to_sns_arn
  ec2_security_groups  = [module.sg.ecs_sg_id]
  alb_security_groups  = [module.sg.alb_sg_id]
  public_subnets       = data.terraform_remote_state.project-core.outputs.public_subnets
  private_subnets      = data.terraform_remote_state.project-core.outputs.private_subnets
  vpc_id               = data.terraform_remote_state.project-core.outputs.vpc_common_id
}
