terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region-name
}

resource "aws_vpc" "BlayVPC" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "custom_public_subnet1" {
  vpc_id                  = aws_vpc.BlayVPC.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az1

  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "custom_public_subnet2" {
  vpc_id                  = aws_vpc.BlayVPC.id
  cidr_block              = var.subnet2_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az2

  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.BlayVPC.id

  tags = {
    Name = "rds_sg"
  }
}

resource "aws_security_group_rule" "rds_sg_mysql" {
  security_group_id = aws_security_group.rds_sg.id
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["10.50.0.0/16"]
}

resource "aws_db_instance" "blaydb_rds" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name                 = "blay_db"
  username             = "Blay"
  password             = "Metro123"
  db_subnet_group_name = aws_db_subnet_group.blaydb_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = "blays3bucket"
  acl   = "private"

  tags = {
    Name = "privateBucket"
  }
}

resource "aws_iam_role" "blayiam_role" {
  name               = "blayiam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "blayiam_policy" {
  name        = "Blayiam-policy"
  description = "Policy for EC2 to access S3"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "s3:*"
      Resource  = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "Blayiam_attachment" {
  role       = aws_iam_role.blayiam_role.name
  policy_arn = aws_iam_policy.blayiam_policy.arn
}

# Create a KMS key
resource "aws_kms_key" "my_kms_key" {
  description             = "My KMS key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# Create an Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "my-application-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.custom_public_subnet1.id, aws_subnet.custom_public_subnet2.id]
  security_groups    = [aws_security_group.alb_sg.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}
