terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }

    backend "local" {
      path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
    command     = "aws"
  }
}

locals {
  vpc_name = "${var.cluster_name}-vpc"
  eks_cluster_name = "${var.cluster_name}"
  dynamodb_table_name = "${var.cluster_name}-state"

  unison_credentials_file = "~/.local/share/unisonlanguage/credentials.json"
  unison_credentials = jsondecode(fileexists(local.unison_credentials_file) ? file(local.unison_credentials_file) : "{\"credentials\":{\"default\": {\"api.unison-lang.org\": {\"tokens\": {\"access_token\": \"\"}}}}}")
  unison_token = local.unison_credentials.credentials.default["api.unison-lang.org"].tokens.access_token
}

