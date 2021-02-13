#tells OS to invoke the specified shell to execute commands in this script
#!/bin/bash
set +ex #disables printing of executed commands to the terminal

#convert to json format - removing comma, spaces inside brackets and newlines  
#Acts like an array due to brackets, use jq to extract value of array[0]
HOSTS_IP=$(cd ../infra && terraform output -json instance_public_ip | jq '.[0]')
DB_USER=$(cd ../infra && terraform output db_username)
DB_PASS=$(cd ../infra && terraform output db_password)
DB_NAME=$(cd ../infra && terraform output db_name)
DB_PORT=$(cd ../infra && terraform output db_port)
DB_HOST=$(cd ../infra && terraform output db_host)

#overwrite with new contents in existing inventory or create new file with contents
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

FILE=~/.ssh/ServianSSHKeyPair
if [[ -f "$FILE" ]]; then
#If file exists, script runs locally, including the file in ansible request
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.yml -e 'record_host_keys=False' -u ec2-user --private-key ${FILE} playbook.yml
else #If file doesn't exist, script runs in pipeline and SSH key is set globally
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.yml -e 'record_host_keys=False' -u ec2-user playbook.yml
fi #Global SSH key applied to all connections and file not required in the command