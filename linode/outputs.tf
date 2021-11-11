output "nomad_server_ip_address" {
  value = linode_instance.nomad_server.ip_address
}

output "nginx_node_ip_address" {
  value = linode_instance.nginx_node.ip_address
}

output "nomad_mgmt_token" {
  value = data.external.nomad_bootstrap_acl.result.token
}

output "consul_mgmt_token" {
  value = var.consul_mgmt_token
  sensitive = true
}

output "docker_domain" {
  value = var.docker_domain
}
output "rails_domain" {
  value = var.rails_domain
}

output "nomad_domain" {
  value = var.nomad_domain
}
