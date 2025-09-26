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
  description = "Name of the EKS cluster"
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

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
  default     = "1.33"
}

variable "desired_node_count" {
  type        = number
  description = "Number of worker nodes"
  default     = 3
}

variable "eks_instance_type" {
  type        = string
  description = "Instance type for worker nodes"
  default     = "t3.medium"
}

variable "kubernetes_admins" {
  type = list(string)
  description = "list of user arn's that get admin access to eks in addition to the user creating the cluster. A user can learn their ARN with `aws iam get-user | jq .User.Arn`"
  default = []
}

variable "unison_vpc_cidr" {
  type        = string
  description = "CIDR block for the Unison VPC"
  default     = "172.20.0.0/16"
}

variable "unison_cloud_image_tag" {
  type        = string
  description = "Tag/version for the unisoncomputing/unison-cloud container image"
  default     = "latest"
}
