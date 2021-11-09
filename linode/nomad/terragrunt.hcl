include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules//nomad"
}

dependency "vm" {
  config_path = "../vm"
  mock_outputs_allowed_terraform_commands = ["init", "plan"]
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
  nomad_server_ip_address = dependency.vm.outputs.nomad_server_ip_address
  nginx_node_ip_address = dependency.vm.outputs.nginx_node_ip_address
  consul_mgmt_token = dependency.vm.outputs.consul_mgmt_token
  docker_domain = dependency.vm.outputs.docker_domain
  rails_domain = dependency.vm.outputs.rails_domain
  nomad_domain = dependency.vm.outputs.nomad_domain
  path_to_certs = abspath("./certs")
}

terraform {
  extra_arguments "common_vars" {
    commands = ["plan", "apply", "destroy"]

    arguments = [
      "-var-file=./secrets.tfvars"
    ]
  }
}
