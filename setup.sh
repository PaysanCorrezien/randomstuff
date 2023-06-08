#!/bin/bash

# Install required packages
sudo apt-get update
sudo apt-get install -y curl git python3 python3-pip python3-setuptools

# Install Ansible
sudo apt-get update
sudo apt-get install -y ansible

# Download the playbook from the GitHub repository
curl -L https://raw.githubusercontent.com/paysancorrezien/randomstuff/main/debian.yml --output playbook.yml

# Execute the playbook
ansible-playbook playbook.yml -K

