resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "security-group-eu-west-1" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "security-group-eu-west-1"
  description = "HTTP security group."
  vpc_id      = module.vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "Open internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  ingress_with_cidr_blocks = [

    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    env     = "production"
    project = "my-project"

  }
}

  module "ec2_cluster" {
    source                 = "terraform-aws-modules/ec2-instance/aws"
    version                = "~> 2.0"
  
    name                   = "my-cluster"
    instance_count         = 2
  
    ami                    = "ami-ebd02392"
    instance_type          = "t2.micro"
    key_name               = aws_key_pair.mykey.key_name
    monitoring             = true
    vpc_security_group_ids = [module.security-group-eu-west-1.this_security_group_id]
    subnet_id              = module.vpc.public_subnets[0]
  
    tags = {
      Terraform   = "true"
      Environment = "production"
    }
  }
