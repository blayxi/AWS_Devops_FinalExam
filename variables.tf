variable "region" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
  default     = "vpc-047cf7f81f14a9166"  # Updated VPC ID
}

variable "subnet_ids" {
  description = "List of Subnet IDs for resources"
  type        = list(string)
  default     = ["subnet-086b85451e097b037", "subnet-0d2aed6c38329a9db"]  # Updated subnet IDs
}

variable "ami_id" {
  description = "The AMI ID for the launch configuration"
  type        = string
  default     = "ami-071a42ffa63391c66"  # Updated AMI ID
}
