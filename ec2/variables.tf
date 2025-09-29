variable "aws_region" {
  type        = string
  description = "AWS region for the resources"
}

variable "aws_availability_zones" {
  type        = list(string)
  description = "Availability zones for the VPC"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster"

  validation {
    condition     = var.cluster_name != "CHANGE_ME"
    error_message = "You must edit the project_name variable from its default value before deploying."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR of public subnets"
  default     = ["10.0.20.0/25", "10.0.20.128/25"]
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR of private subnets"
  default     = ["10.0.30.0/25", "10.0.30.128/25"]
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances to create"
  default     = 3
}

variable "instance_type" {
  type        = string
  description = "Instance type for EC2 instances"
  default     = "t3.medium"
}

variable "unison_cloud_image_tag" {
  type        = string
  description = "Tag/version for the unisoncomputing/unison-cloud container image"
  default     = "latest"
}

variable "unison_instance_type" {
  description = "EC2 instance type for Unison Cloud instances"
  type        = string
  default     = "t3.medium"
}

variable "unison_min_instances" {
  description = "Minimum number of Unison Cloud instances"
  type        = number
  default     = 1
}

variable "unison_max_instances" {
  description = "Maximum number of Unison Cloud instances"
  type        = number
  default     = 8
}

variable "unison_desired_instances" {
  description = "Desired number of Unison Cloud instances"
  type        = number
  default     = 2
}
