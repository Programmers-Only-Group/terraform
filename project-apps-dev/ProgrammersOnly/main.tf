### ECS CLUSTER
resource "aws_ecs_cluster" "programmers_only" {
  name = "ProgrammersOnly"
}

### ASG
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-*-amazon-ecs-optimized",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

data "template_file" "user_data" {
  template = "${file("userdata.sh")}"
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "userdata.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.user_data.rendered
  }
}

resource "aws_launch_configuration" "programmers_only" {
  name_prefix                 = "programmers-only"
  image_id                    = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  user_data                   = data.template_cloudinit_config.config.rendered
  key_name                    = var.key_name
  iam_instance_profile        = var.iam_instance_profile
  security_groups             = var.security_groups
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  ebs_block_device {
    device_name = "/dev/xvdcz"
    volume_size = 22
  }
}

resource "aws_autoscaling_group" "programmers_only" {
  availability_zones   = ["eu-west-1a", "eu-west-1b"]
  name                 = "programmers-only"
  vpc_zone_identifier  = var.subnets
  launch_configuration = aws_launch_configuration.programmers_only.name
  min_size             = 0
  max_size             = 2
  desired_capacity     = 0

  tags = [
    {
      "key"                 = "Name"
      "value"               = format("%s-ecs", var.prefix)
      "propagate_at_launch" = true
    },
    {
      "key"                 = "Environment"
      "value"               = "dev"
      "propagate_at_launch" = true
    }
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

}

### ECS SERVICES

data "template_file" "nginx" {
  template = "${file("ProgrammersOnly/task_definitions/nginx_task_definition.json")}"
}

resource "aws_ecs_task_definition" "nginx" {
  family                = "nginx"
  container_definitions = file("ProgrammersOnly/task_definitions/nginx_task_definition.json")
}

data "aws_ecs_task_definition" "nginx" {
  task_definition = aws_ecs_task_definition.nginx.family
  depends_on      = [aws_ecs_task_definition.nginx]
}

resource "aws_ecr_repository" "nginx" {
  name = "nginx"
}

resource "aws_ecr_repository_policy" "nginx" {
  repository = aws_ecr_repository.nginx.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "NGINX_ECR",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecs_service" "nginx" {
  name                               = "nginx"
  cluster                            = aws_ecs_cluster.programmers_only.id
  task_definition                    = "nginx:${data.aws_ecs_task_definition.nginx.revision}"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
}
