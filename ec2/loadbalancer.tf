# Generate TLS certificate for the load balancer hostname
resource "tls_private_key" "proxy_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "proxy_cert" {
  private_key_pem = tls_private_key.proxy_key.private_key_pem

  subject {
    common_name  = aws_lb.main.dns_name
    organization = "Unison BYOC"
    country      = "US"
    province     = "MA"
    locality     = "Boston"
  }

  dns_names = [
    aws_lb.main.dns_name,
    "localhost"
  ]

  ip_addresses = [
    "127.0.0.1"
  ]

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Security group for load balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-alb-sg"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name        = "${var.cluster_name}-alb"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}

# Target group for Unison Cloud instances
resource "aws_lb_target_group" "unison" {
  name     = "${var.cluster_name}-unison-tg"
  port     = 8082
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-299"
    path                = "/health"
    port                = "8081"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.cluster_name}-unison-tg"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}


# ALB Listener for HTTP (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener for HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.proxy.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.unison.arn
  }
}

# Upload certificate to ACM
resource "aws_acm_certificate" "proxy" {
  private_key      = tls_private_key.proxy_key.private_key_pem
  certificate_body = tls_self_signed_cert.proxy_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.cluster_name}-proxy-cert"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}
