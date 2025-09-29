aws_region = "us-west-1"
aws_availability_zones = ["us-west-1a", "us-west-1b"]

# You must change the cluster_name before deploying. 
# The new name must consistsolely of letters, numbers, and hyphens.

cluster_name = "CHANGE_ME"

# Optional variables with default values that can be overridden.
# See varaibles.tf for descriptions:

#kubernetes_admins = [
#    "arn:aws:iam::123456789012:user/username1", 
#    "arn:aws:iam::123456789012:user/username2"
#]

# vpc_cidr = "10.0.0.0/16"
# public_subnets = ["10.0.20.0/25", "10.0.20.128/25"]
# private_subnets = ["10.0.30.0/25", "10.0.30.128/25"]

# cluster_version = "1.30"
# desired_node_count = 3
# eks_instance_type = "t3.medium"
# unison_cloud_image_tag = "latest"
