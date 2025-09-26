
output "unison_public_endpoint_https" {
  value = "https://${aws_lb.main.dns_name}"
  description = "Public HTTPS endpoint for Unison Cloud API (with self-signed cert)"
}

resource "local_file" "cluster_setup_script" {
  filename = "${path.module}/outputs/cluster-setup.u"
  content = <<EOF
{{
In order to connect to your cluster, You'll need to use a custom cluster config:
}}

clusterConfig = do
  certs = """${tls_self_signed_cert.proxy_cert.cert_pem}"""
                |> toUtf8
                |> decodeCert
                |> Exception.reraise
                |> List.singleton
  
  hostname = HostName "${var.cluster_name}.byoc.unison.cloud"
  Cloud.ClientConfig.default() 
     |> ClientConfig.host.set hostname
     |> ClientConfig.httpConfig.modify (client.Config.trustedCerts.modify (c -> c ++ certs))

-- Instead of calling Cloud.run, which, by default, targets the Unison public cluster,
-- use Cloud.run.withConfig to target your own cluster:

myJob = do Cloud.run.withConfig clusterConfig() do
    env = default()
    two = submit env do
      1 + 1
    printLine ("remotely calculated: 1 + 1 = " ++ (Nat.toText two))
EOF
}

output "cluster_setup_u" {
  sensitive = false
  description = "Unison script to connect to your cluster"
  value = local_file.cluster_setup_script.content
}