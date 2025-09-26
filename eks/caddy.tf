# Generate TLS certificate for the load balancer hostname
resource "tls_private_key" "caddy_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "caddy_cert" {
  private_key_pem = tls_private_key.caddy_key.private_key_pem

  subject {
    common_name  = kubernetes_service_v1.caddy_service.status[0].load_balancer[0].ingress[0].hostname
    organization = "Unison BYOC"
    country      = "US"
    province     = "MA"
    locality     = "Boston"
  }

  dns_names = [
    kubernetes_service_v1.caddy_service.status[0].load_balancer[0].ingress[0].hostname,
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

# Caddy reverse proxy with automatic HTTPS
resource "kubernetes_service_v1" "caddy_service" {
  depends_on = [module.eks,
                aws_eks_access_entry.admin_access,
                aws_eks_access_policy_association.admin_cluster_access,
                aws_eks_access_policy_association.admin_namespace_access
               ]

  metadata {
    name = "caddy-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
    }
  }

  spec {
    selector = {
      app = "caddy"
    }
    
    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    
    port {
      name        = "https"
      port        = 443
      target_port = 443
      protocol    = "TCP"
    }
    
    type = "LoadBalancer"
  }
}

resource "kubernetes_config_map" "caddy_config" {
  depends_on = [kubernetes_service_v1.caddy_service]

  metadata {
    name = "caddy-config"
  }

  data = {
    "Caddyfile" = <<EOF
{
  # Disable automatic HTTPS since we're providing our own cert
  auto_https off
}

${kubernetes_service_v1.caddy_service.status[0].load_balancer[0].ingress[0].hostname}:443 {
  tls /etc/caddy/certs/server.crt /etc/caddy/certs/server.key
  reverse_proxy unison-service-public:8082
}

:80 {
  redir https://${kubernetes_service_v1.caddy_service.status[0].load_balancer[0].ingress[0].hostname}{uri} permanent
}
EOF
  }
}

resource "kubernetes_secret" "caddy_tls" {
  metadata {
    name = "caddy-tls"
  }

  data = {
    "server.crt" = tls_self_signed_cert.caddy_cert.cert_pem
    "server.key" = tls_private_key.caddy_key.private_key_pem
  }

  type = "Opaque"
}

resource "kubernetes_deployment_v1" "caddy" {
  depends_on = [kubernetes_config_map.caddy_config, kubernetes_secret.caddy_tls]

  metadata {
    name = "caddy"
    labels = {
      app = "caddy"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "caddy"
      }
    }

    template {
      metadata {
        labels = {
          app = "caddy"
        }
      }

      spec {        
        container {
          name  = "caddy"
          image = "caddy:2"

          port {
            container_port = 80
            name           = "http"
          }

          port {
            container_port = 443
            name           = "https"
          }

          volume_mount {
            name       = "caddy-config"
            mount_path = "/etc/caddy"
            read_only  = true
          }

          volume_mount {
            name       = "caddy-certs"
            mount_path = "/etc/caddy/certs"
            read_only  = true
          }

          volume_mount {
            name       = "caddy-data"
            mount_path = "/data"
          }

          volume_mount {
            name       = "caddy-config-cache"
            mount_path = "/config"
          }
        }

        volume {
          name = "caddy-config"
          config_map {
            name = kubernetes_config_map.caddy_config.metadata[0].name
          }
        }

        volume {
          name = "caddy-certs"
          secret {
            secret_name = kubernetes_secret.caddy_tls.metadata[0].name
          }
        }

        volume {
          name = "caddy-data"
          empty_dir {}
        }

        volume {
          name = "caddy-config-cache"
          empty_dir {}
        }
      }
    }
  }
}
