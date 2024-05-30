provider "aws" {
  region = var.region
}

# Create S3 Bucket
resource "aws_s3_bucket" "sbk_s3_bucket" {
  bucket = "blaytfs3bucket"
}

# IAM Role
resource "aws_iam_role" "sbk_iam_role" {
  name = "sbk_iam_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "sbk_iam_profile" {
  name = "sbk_iam_profile"
  role = aws_iam_role.sbk_iam_role.name
}

# IAM Policy
resource "aws_iam_policy" "sbk_policy" {
  name        = "sbk_policy"
  description = "A sample policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:ListBucket"]
      Effect   = "Allow"
      Resource = ["arn:aws:s3:::${aws_s3_bucket.sbk_s3_bucket.bucket}"]
    }]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.sbk_iam_role.name
  policy_arn = aws_iam_policy.sbk_policy.arn
}

# Security Group
resource "aws_security_group" "sbk_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "blaydb_subnet_group" {
  name       = "blaydb-subnet-group"
  subnet_ids = var.subnet_ids
}

# RDS Instance
resource "aws_db_instance" "sbk_rds" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  identifier           = "sbkdatabase1"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.sbk_sg.id]
  db_subnet_group_name = aws_db_subnet_group.blaydb_subnet_group.name
}

# KMS Key
resource "aws_kms_key" "sbk_key" {
  description             = "KMS key for encryption"
  deletion_window_in_days = 10
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "sbk_lb" {
  name               = "sbk-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

# Launch Configuration
resource "aws_launch_configuration" "sbk_lc" {
  name                = "sbk-lc"
  image_id            = var.ami_id
  instance_type       = "t2.micro"
  security_groups     = [aws_security_group.sbk_sg.id]
  iam_instance_profile = aws_iam_instance_profile.sbk_iam_profile.name
}

# AutoScaling Group
resource "aws_autoscaling_group" "sbk_asg" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = var.subnet_ids
  launch_configuration = aws_launch_configuration.sbk_lc.id

  tag {
    key                 = "Name"
    value               = "sbk-asg-instance"
    propagate_at_launch = true
  }
}

# AWS Glue Job
resource "aws_glue_job" "sbk_glue_job" {
  name     = "sbk-glue-job"
  role_arn = aws_iam_role.sbk_iam_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.sbk_s3_bucket.bucket}/scripts/glue_script.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language" = "python"
  }

  max_retries = 1
}
