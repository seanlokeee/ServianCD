#!/bin/bash
set +ex
echo "all:" > inventory.yml
echo " hosts:" >> inventory.yml
#convert to json format and since it has brackets, acts like an array, use jq to extract value of array[0]
echo "   $(cd ../infra && terraform output -json instance_public_ip | jq '.[0]'):" >> inventory.yml
echo "      db_username_i: \"$(cd ../infra && terraform output db_username)\"" >> inventory.yml
echo "      db_password_i: \"$(cd ../infra && terraform output db_password)\"" >> inventory.yml
echo "      db_name_i: \"$(cd ../infra && terraform output db_name)\"" >> inventory.yml
echo "      db_port_i: \"$(cd ../infra && terraform output db_port)\"" >> inventory.yml
echo "      db_host_i: \"$(cd ../infra && terraform output db_host)\"" >> inventory.yml
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.yml -e 'record_host_keys=False' -u ec2-user --private-key ~/.ssh/id_rsa.pem playbook.yml