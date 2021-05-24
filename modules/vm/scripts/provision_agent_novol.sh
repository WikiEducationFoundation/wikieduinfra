#!/usr/bin/env bash
[ `whoami` = root ] || exec su -c $0 root

sudo mkdir --parents /etc/nomad.d
sudo chmod 700 /etc/nomad.d

sudo touch /etc/nomad.d/client.hcl
sudo echo "client {
  enabled = true
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

  ca_file = \"/root/consul-agent-certs/consul-agent-ca.pem\"
  cert_file = \"/root/consul-agent-certs/dc1-client-consul-0.pem\"
  key_file = \"/root/consul-agent-certs/dc1-client-consul-0-key.pem\"
}

tls {
  http = true
  rpc  = true

  ca_file = \"/root/nomad-agent-certs/nomad-agent-ca.pem\"
  cert_file = \"/root/nomad-agent-certs/global-client-nomad-0.pem\"
  key_file = \"/root/nomad-agent-certs/global-client-nomad-0-key.pem\"

  verify_server_hostname = true
  verify_https_client    = true
}
" >> /etc/nomad.d/client.hcl

sudo systemctl enable nomadclient
sudo systemctl start nomadclient