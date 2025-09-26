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
  input = aws_lb.main.dns_name
}

data "http" "set_cluster_uri" {
    url = "https://api.unison.cloud/v2/byoc/clusters/${data.http.cluster_id.response_body}/clusterUri"

    method = "POST"

    request_headers = {
      Authorization = "Bearer ${local.unison_token}"
      Content-Type  = "application/json"
    }

    request_body = jsonencode("https://${terraform_data.cluster_uri.output}")

    depends_on = [terraform_data.cluster_uri]
}

output "cluster_id" {
  value = data.http.cluster_id.response_body
}

output "cluster_token" {
  value = data.http.cluster_token.response_body
  sensitive = true
}

output "set_cluster_uri_response" {
  value = data.http.set_cluster_uri.response_body
}