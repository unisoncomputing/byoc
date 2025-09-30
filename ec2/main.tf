terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}


# Data source to get current AWS account info
data "aws_caller_identity" "current" {}

# Data source to get current AWS region
data "aws_region" "current" {}

# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  vpc_name = "${var.cluster_name}-vpc"
  dynamodb_table_name = "${var.cluster_name}-state"
  bastion_sg_name = "${var.cluster_name}-bastion-sg"

  unison_credentials_file = "~/.local/share/unisonlanguage/credentials.json"
  unison_credentials = jsondecode(fileexists(local.unison_credentials_file) ? file(local.unison_credentials_file) : "{\"default\": {\"api.unison-lang.org\": {\"tokens\": {\"access_token\": \"\"}}}}")
  unison_token = local.unison_credentials.credentials.default["api.unison-lang.org"].tokens.access_token
}

