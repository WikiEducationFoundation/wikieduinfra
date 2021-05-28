#!/usr/bin/env bash

sudo mkdir -p /data/mariadb
sudo echo "client {
  enabled = true

  host_volume \"mariadb\" {
    path      = \"/data/mariadb/\"
    read_only = false
  }

  meta = {
    \"mariadb_node\" = \"true\"
    \"reserved_node\" = \"true\"
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