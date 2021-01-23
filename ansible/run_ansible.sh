#!/bin/bash
set +ex

#convert to json format - removing comma, spaces inside brackets and newlines  
#Acts like an array due to brackets, use jq to extract value of array[0]
HOSTS_IP=$(cd ../infra && terraform output -json instance_public_ip | jq '.[0]')
DB_USER=$(cd ../infra && terraform output db_username)
DB_PASS=$(cd ../infra && terraform output db_password)
DB_NAME=$(cd ../infra && terraform output db_name)
DB_PORT=$(cd ../infra && terraform output db_port)
DB_HOST=$(cd ../infra && terraform output db_host)

cat << EOF > inventory.yml
all: 
    hosts:
        ${HOSTS_IP}:
            db_username_i: "${DB_USER}" 
            db_password_i: "${DB_PASS}" 
            db_name_i: "${DB_NAME}"
            db_port_i: "${DB_PORT}"
            db_host_i: "${DB_HOST}"
EOF

FILE=~/.ssh/id_rsa.pem
if [[ -f "$FILE" ]]; then
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.yml -e 'record_host_keys=False' -u ec2-user --private-key ${FILE} playbook.yml
else
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.yml -e 'record_host_keys=False' -u ec2-user playbook.yml
fi