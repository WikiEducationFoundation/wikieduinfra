include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../..//linode"

  extra_arguments "common_vars" {
    commands = ["plan", "apply", "destroy"]

    arguments = [
      "-var-file=./secrets.tfvars"
    ]
  }
}
