data "http" "cluster_id" {
    url = "https://api.unison.cloud/v2/byoc/clusters/${var.cluster_name}"

    method = "POST"

    request_headers = {
      Authorization = "Bearer ${local.unison_token}"
    }
}

data "http" "cluster_token" {
    url = "https://api.unison.cloud/v2/byoc/clusters/${data.http.cluster_id.response_body}/token"

    method = "POST"

    request_headers = {
      Authorization = "Bearer ${local.unison_token}"
    }
}

resource "terraform_data" "cluster_uri" {
  input = kubernetes_service_v1.caddy_service.status[0].load_balancer[0].ingress[0].hostname
}



data "http" "set_cluster_uri" {
    url = "https://api.unison.cloud/v2/byoc/clusters/${data.http.cluster_id.response_body}/clusterUri"

    method = "POST"

    request_headers = {
      Authorization = "Bearer ${local.unison_token}"
      Content-Type  = "application/json"
    }

    request_body = jsonencode("https://${terraform_data.cluster_uri.output}")

    depends_on = [kubernetes_service_v1.caddy_service, terraform_data.cluster_uri]
}

