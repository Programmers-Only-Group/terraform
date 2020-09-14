
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

module "sg" {
  source = "./security"

  vpc_id = data.terraform_remote_state.project-core.outputs.vpc_common_id
}

data "aws_route53_zone" "programmers_only" {
  name         = "programmers-only.com."
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.programmers_only.zone_id
  name    = "www.programmers-only.com"
  type    = "A"
  ttl     = "300"
  records = ["52.58.100.247"]
}

module "ProgrammersOnly" {
  source = "./ProgrammersOnly"

  prefix               = "programmers-only"
  key_name             = data.terraform_remote_state.project-core.outputs.key_name
  iam_instance_profile = data.terraform_remote_state.project-iam.outputs.instance_profile_ec2
  security_groups      = [module.sg.ecs_sg_id]
  subnets              = data.terraform_remote_state.project-core.outputs.subnets
}
