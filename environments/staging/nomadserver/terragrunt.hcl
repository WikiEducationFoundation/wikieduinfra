include {
  path = find_in_parent_folders()
}

dependency "linode" {
  config_path = "../linode"
  mock_outputs_allowed_terraform_commands = ["init"]
  mock_outputs = {
    nomad_server_ip_address = "1"
    nginx_node_ip_address = "1"
    nomad_mgmt_token = "1"
    docker_domain = "1"
    rails_domain = "1"
    nomad_domain = "1"
    consul_mgmt_token = "1"
    docker_pass_encrypted = "1"
  }
}

inputs = {
  nomad_server_ip_address = dependency.linode.outputs.nomad_server_ip_address
  nginx_node_ip_address = dependency.linode.outputs.nginx_node_ip_address
  nomad_mgmt_token = dependency.linode.outputs.nomad_mgmt_token
  consul_mgmt_token = dependency.linode.outputs.consul_mgmt_token
  docker_domain = dependency.linode.outputs.docker_domain
  rails_domain = dependency.linode.outputs.rails_domain
  nomad_domain = dependency.linode.outputs.nomad_domain
  path_to_certs = abspath("./certs")
}

terraform {
  source = "../../..//nomadserver"

  extra_arguments "common_vars" {
    commands = ["plan", "apply", "destroy"]

    arguments = [
      "-var-file=./secrets.tfvars"
    ]
  }
}
