variable "consul_mgmt_token" {
  type        = string
  description = <<EOT
    Token used to secure Consul - this token grants global permissions to bearer.
    Use `openssl rand -hex 24` to generate a sufficiently random value.
  EOT
  # sensitive   = true
}

variable "consul_gossip_token" {
  type    = string
  description = <<EOT
    Token used to secure Consul gossip protocol.
    Use `openssl rand -hex 24` to generate.
  EOT
  # sensitive = true
}

variable "new_relic_license_key" {
  type    = string
  description = "Your New Relic License Key. Used to stand up the Infra Agent."
  # sensitive = true
}

variable "linode_token" {
  type    = string
  description = "Your Linode Access Token."
  # sensitive = true
}

variable "root_pass" {
  type = string
  description = <<EOT
    All root passwords will be set to this value.
    Use `openssl rand -hex 16` to generate a sufficiently random value.
  EOT
  # sensitive = true
}

variable "docker_domain" {
  type = string
  description = "FQDN where the docker registry will be hosted"
  default = "docker.wikiedu.org"
}

variable "rails_domain" {
  type = string
  description = "FQDN where the Rails app will be hosted"
  default = "dashboard.wikiedu.org"
}

variable "nomad_domain" {
  type = string
  description = "Domain for the Nomad UI"
  default = "nomad.wikiedu.org"
}

variable "letsencrypt_email" {
  type = string
  description = "Email address for LE certs"
  default = "sage@wikiedu.org"
}

variable "ssh_pubkey" {
  type = string
  description = "Local path to the SSH public key for accessing the cluster"
}
variable "ssh_privkey" {
  type = string
  description = "Local path to the SSH private key for accessing the cluster"
}
variable "path_to_certs"{
  type = string
  description = "Absolute path to the directory containing the nomad/consul certs (which are generated on the nomad server via the provisioning script, then copied to your local machine)"
}
