module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37.2"

  cluster_name    = local.eks_cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  node_security_group_additional_rules = {
    ingress_worker_vpc = {
      protocol                      = "tcp"
      from_port                     = 0
      to_port                       = 65535
      type                          = "ingress"
      cidr_blocks                   = ["10.0.0.0/8"]
      description                   = "Allow traffic within VPC"
    }
  }
  cluster_security_group_additional_rules = {}

  eks_managed_node_groups = {
    default = {
      min_size       = var.desired_node_count
      max_size       = var.desired_node_count + 2
      desired_size   = var.desired_node_count
      instance_types = [var.eks_instance_type]
      iam_role_additional_policies = {
        s3       = aws_iam_policy.byoc_container_s3_policy.arn
        dynamodb = aws_iam_policy.byoc_container_dynamo_policy.arn
        ecr      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  tags = {
    "Environment" = "byoc"
  }

  depends_on = [module.vpc]
}

resource "aws_eks_access_entry" "admin_access" {
  depends_on    = [module.eks]
  count         = length(var.kubernetes_admins)
  cluster_name  = module.eks.cluster_name
  principal_arn = var.kubernetes_admins[count.index]
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_cluster_access" {
  depends_on   = [module.eks]
  count        = length(var.kubernetes_admins)
  cluster_name = module.eks.cluster_name

  # for a list of possibilities to put here, run:
  # aws eks list-access-policies --output table

  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.kubernetes_admins[count.index]

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "admin_namespace_access" {
  depends_on   = [module.eks]
  count        = length(var.kubernetes_admins)
  cluster_name = module.eks.cluster_name

  # for a list of possibilities to put here, run:
  # aws eks list-access-policies --output table

  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = var.kubernetes_admins[count.index]

  access_scope {
    type       = "namespace"
    namespaces = ["default"]
  }
}

