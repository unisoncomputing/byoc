output "list-eks-nodes-command" {
  value = <<EOF
aws --region ${var.aws_region} ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=${var.cluster_name}" \
  --query "Reservations[].Instances[].{Hostname:PrivateDnsName, Type:InstanceType, Health:State.Name}" \
  --output table
EOF
  description = "command to get the health of the EKS nodes"
}

output "unison_public_endpoint_https" {
  value = "https://${aws_lb.main.dns_name}"
  description = "Public HTTPS endpoint for Unison Cloud API (with self-signed cert)"
}

resource "local_file" "cluster_config_script" {
  filename = "${path.module}/outputs/cluster-config.u"
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

sampleJob = do Cloud.run.withConfig clusterConfig() do
    env = default()
    two = submit env do
      1 + 1
    printLine ("remotely calculated: 1 + 1 = " ++ (Nat.toText two))
EOF
}

output "cluster_config_u" {
  sensitive = false
  description = "Unison script to connect to your cluster"
  value = local_file.cluster_config_script.content
}
