# Security group for Unison Cloud instances
resource "aws_security_group" "unison" {
  name_prefix = "${var.cluster_name}-unison-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Health check from ALB"
    from_port       = 8081
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Health check from internal NLB"
    from_port   = 8081
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, "0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-unison-sg"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}

locals {
  unison_user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    unison_cloud_image_tag = var.unison_cloud_image_tag
    region                 = data.aws_region.current.name
    config_template        = base64encode(data.template_file.config_template.rendered)
  }))
}

data "template_file" "config_template" {
  template = file("${path.module}/config.json.template")
  vars = {
    blob_bucket_name     = aws_s3_bucket.unison_cloud_byoc_blobs.bucket
    services_bucket_name = aws_s3_bucket.unison_cloud_byoc_native_services.bucket
    cluster_token        = data.http.cluster_token.response_body
    region               = data.aws_region.current.name
    dynamodb_table       = aws_dynamodb_table.unison_cloud_byoc_state.id
    cluster_name         = var.cluster_name
  }
}

resource "aws_launch_template" "unison" {
  name_prefix   = "${var.cluster_name}-unison-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.unison_instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.unison.id]
    delete_on_termination       = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.unison.name
  }

  user_data = local.unison_user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.cluster_name}-unison"
      Environment = "byoc"
      Project     = "unison-cloud"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.cluster_name}-unison-lt"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}

resource "aws_autoscaling_group" "unison" {
  name                      = "${var.cluster_name}-unison-asg"
  vpc_zone_identifier       = module.vpc.private_subnets
  target_group_arns         = [aws_lb_target_group.unison.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.unison_min_instances
  max_size         = var.unison_max_instances
  desired_capacity = var.unison_desired_instances

  launch_template {
    id      = aws_launch_template.unison.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-unison-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = "byoc"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "unison-cloud"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}
