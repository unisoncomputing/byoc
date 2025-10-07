resource "kubernetes_network_policy_v1" "unison_network_policy" {

  depends_on = [module.eks, 
                aws_eks_access_entry.admin_access,
                aws_eks_access_policy_association.admin_cluster_access,
                aws_eks_access_policy_association.admin_namespace_access
              ]

  metadata {
    name      = "unison-network-policy"
    namespace = "default"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "unison-cloud"
      }
    }

    # Allow public access to port 8082 from anywhere
    ingress {
      ports {
        protocol = "TCP"
        port     = 8082
      }
    }
    
    # Allow internal gossip communication between pods
    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "unison-cloud"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 8081
      }
    }

    egress {}

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_config_map" "unison-cloud-config" {
  depends_on = [module.eks,
                 aws_eks_access_entry.admin_access,
                 aws_eks_access_policy_association.admin_cluster_access,
                 aws_eks_access_policy_association.admin_namespace_access
               ]

  metadata {
    name = "unison-cloud-config-template"
  }

  data = {
    renderTemplate          = <<EOF
      #!/bin/sh

      sed 's/{{POD_IP}}/'$${POD_IP}'/g ; s/{{CLUSTER_TOKEN}}/${data.http.cluster_token.response_body}/g' \
        < /etc/nimbus-template/config.json.template \
        > /etc/nimbus/secrets/partial-config.json
EOF
    "config.json.template" = <<EOF
        {
            "host": "{{POD_IP}}",
            "bindPorts": {
              "publicHttp": 8082,
              "gossipHttp": 8081
            },
            "blobFetcher": {
              "bucket": "${aws_s3_bucket.unison_cloud_byoc_native_services.id}",
              "awsConfig": {
                  "region": "${var.aws_region}"
              }
            },
            "userBlobFetcher": {
              "bucket": "${aws_s3_bucket.unison_cloud_byoc_blobs.id}",
              "awsConfig": {
                  "region": "${var.aws_region}"
              }
            },
            "environmentsMount": "environments-staging",
            "dynamo": {
              "type": "cloud",
              "region": "${var.aws_region}",
              "table": "${aws_dynamodb_table.unison_cloud_byoc_state.id}"
            },
            "cloudApiToken": "{{CLUSTER_TOKEN}}",
            "cloudApiInstances": [
              {
                "uri": "https://${var.cluster_name}.byoc.unison.cloud"
              }
            ],
            "tcpConfig" : { "type": "everybody" }
        }
EOF
  }

}

resource "kubernetes_deployment_v1" "unison_deployment" {
  depends_on = [module.eks,
                 aws_eks_access_entry.admin_access,
                 aws_eks_access_policy_association.admin_cluster_access,
                 aws_eks_access_policy_association.admin_namespace_access
               ]
  metadata {
    name = "unison-deployment"
    labels = {
      app = "unison-byoc"
    }
  }

  spec {
    replicas = 4

    selector {
      match_labels = {
        app = "unison-cloud"
      }
    }

    template {
      metadata {
        labels = {
          app = "unison-cloud"
        }
      }

      spec {
        init_container {
          name    = "config-init"
          image   = "busybox"
          command = ["/bin/sh", "-c", "sh /etc/nimbus-template/renderTemplate"]
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          volume_mount {
            name       = "nimbus-config"
            mount_path = "/etc/nimbus/secrets"
            read_only  = false
          }
          volume_mount {
            name       = "nimbus-config-template"
            mount_path = "/etc/nimbus-template"
            read_only  = true
          }
        }
        container {
          name  = "unison-cloud"
          image = "unisoncomputing/unison-cloud:${var.unison_cloud_image_tag}"

          port {
            container_port = 8082
            name           = "http-public"
          }

          port {
            container_port = 8081
            name           = "http-gossip"
          }

          env {
            name  = "NIMBUS_MAX_CONNECTIONS_PER_HOST"
            value = 64
          }
          env {
            name  = "NIMBUS_CONFIG_DIR"
            value = "/etc/nimbus/secrets"
          }
          env {
            name  = "NIMBUS_POLL_IAM_CREDENTIALS"
            value = true
          }
          volume_mount {
            name       = "nimbus-config"
            mount_path = "/etc/nimbus/secrets"
            read_only  = false
          }
          startup_probe {
            http_get {
              path = "/ready"
              port = "http-gossip"
            }
            initial_delay_seconds = 1
            timeout_seconds       = 2
            period_seconds        = 3
            failure_threshold     = 20
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = "http-gossip"
            }
            timeout_seconds       = 6
            period_seconds        = 20
            failure_threshold     = 2
          }
        }
        volume {
          name = "nimbus-config-template"
          config_map {
            name = kubernetes_config_map.unison-cloud-config.metadata[0].name
          }
        }
        volume {
          name = "nimbus-config"
        }
        # Give in-flight jobs/requests some time to wrap up
        termination_grace_period_seconds = 60 * 6
      }
    }
  }
}

# Internal service for gossip communication between pods
resource "kubernetes_service_v1" "unison_service_internal" {
  depends_on = [module.eks,
                 aws_eks_access_entry.admin_access,
                 aws_eks_access_policy_association.admin_cluster_access,
                 aws_eks_access_policy_association.admin_namespace_access
               ]

  metadata {
    name = "unison-service-internal"
  }

  spec {
    selector = {
      app = "unison-cloud"
    }
    port {
      port        = 8081
      target_port = 8081
      name        = "http-gossip"
    }
    type = "ClusterIP"
  }
}

# Public ClusterIP service for Caddy to access
resource "kubernetes_service_v1" "unison_service_public" {
  depends_on = [module.eks,
                 aws_eks_access_entry.admin_access,
                 aws_eks_access_policy_association.admin_cluster_access,
                 aws_eks_access_policy_association.admin_namespace_access
               ]

  metadata {
    name = "unison-service-public"
  }

  spec {
    selector = {
      app = "unison-cloud"
    }
    port {
      port        = 8082
      target_port = 8082
      name        = "http-public"
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}
