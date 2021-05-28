#!/usr/bin/env bash
[ `whoami` = root ] || exec su -c $0 root

# This script configures the nomad client for a generic node.
# It includes a host volume named the same as the node name.

echo "Configuring nomad client via provision_agent_generic.sh..."
sudo mkdir --parents /etc/nomad.d
sudo chmod 700 /etc/nomad.d

sudo mkdir -p /data/persistence

sudo touch /etc/nomad.d/client.hcl
sudo echo "client {
  enabled = true

  host_volume \"node-$1\" {
    path      = \"/data/persistence/\"
    read_only = false
  }
}

datacenter = \"dc1\"
data_dir = \"/opt/nomad\"
name = \"node-$1\"

acl {
  enabled = true
}

bind_addr = \"{{ GetInterfaceIP \\\"eth0\\\" }}\"

consul {
  checks_use_advertise = true
  token = \"$2\"

  ca_file = \"/etc/clusterconfig/consul-agent-certs/consul-agent-ca.pem\"
  cert_file = \"/etc/clusterconfig/consul-agent-certs/dc1-client-consul-0.pem\"
  key_file = \"/etc/clusterconfig/consul-agent-certs/dc1-client-consul-0-key.pem\"
}

tls {
  http = true
  rpc  = true

  ca_file = \"/etc/clusterconfig/nomad-agent-certs/nomad-agent-ca.pem\"
  cert_file = \"/etc/clusterconfig/nomad-agent-certs/global-client-nomad-0.pem\"
  key_file = \"/etc/clusterconfig/nomad-agent-certs/global-client-nomad-0-key.pem\"

  verify_server_hostname = true
  verify_https_client    = true
}
" | sudo tee /etc/nomad.d/client.hcl

sudo systemctl enable nomadclient
sudo systemctl start nomadclient

echo "END: provision_agent_generic.sh"
