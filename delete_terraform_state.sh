#!/bin/bash

echo "Deleting all terraform state..."

rm terraform.tfstate
rm -rf .terraform
rm -rf certs
rm -rf linode/.terraform
rm -rf linode/linode
rm linode/.terraform.lock.hcl
rm -rf nomadserver/.terraform
rm -rf nomadserver/nomadserver
rm nomadserver/.terraform.lock.hcl
rm nomadserver/nomad.sh
