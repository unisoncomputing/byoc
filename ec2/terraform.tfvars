aws_region = "us-west-2"
aws_availability_zones = ["us-west-2a", "us-west-2b"]

# You must change the cluster_name before deploying. 
# The new name must consistsolely of letters, numbers, and hyphens.

cluster_name = "CHANGE_ME"

# Optional variables with default values that can be overridden.
# See varaibles.tf for descriptions:

# vpc_cidr = "10.0.0.0/16"
# public_subnets = ["10.0.20.0/25", "10.0.20.128/25"]
# private_subnets = ["10.0.30.0/25", "10.0.30.128/25"]

# Unison Cloud Configuration
# unison_cloud_image_tag = "latest"
# unison_instance_type = "t3.medium"
# unison_min_instances = 1
# unison_max_instances = 8
# unison_desired_instances = 2
