#!/bin/bash

echo "Creating copies of terraform state..."

mkdir -p terraform_state_copy
cp terraform.tfstate terraform_state_copy/terraform.tfstate
cp -r .terraform terraform_state_copy/.terraform
cp -r certs terraform_state_copy/certs
mkdir -p terraform_state_copy/linode
cp -r linode/.terraform terraform_state_copy/linode/.terraform
cp -r linode/linode terraform_state_copy/linode/linode
cp linode/.terraform.lock.hcl terraform_state_copy/linode/.terraform.lock.hcl

mkdir -p terraform_state_copy/nomadserver
cp -r nomadserver/.terraform terraform_state_copy/nomadserver/.terraform
cp -r nomadserver/nomadserver terraform_state_copy/nomadserver/nomadserver
cp nomadserver/.terraform.lock.hcl terraform_state_copy/nomadserver/.terraform.lock.hcl
cp nomadserver/nomad.sh terraform_state_copy/nomadserver/nomad.sh
