# Documentation of Ansible Folder

Automate deployment of application to the deployed ec2 instance by setting up a playbook which deploys and configures application on the ec2 instance

## Automatically Generate Inventory File

`run_ansible.sh` : commands in this file generate an inventory file which provides all necessary configurations (E.g. IP for ssh and database address)

**Script Explanation:**
- ANSIBLE_HOST_KEY_CHECKING set to false to ignore SSH authenticity checking to avoid any human intervention in middle of script execution
- record_host_keys set to true to record newly discovered and approved (if host key checking is enabled) hosts in the user's hostfile. This setting may be inefficient for large numbers of hosts, and in those situations, using the ssh transport is definitely recommended instead. Setting it to false improves performance and is recommended when host key checking is disabled

## Download Application and Copy to Local Drive

`playbook.yml` : the two separate tasks in this file are downloading the application zip file from github and unzipping it in the remote server (EC2 instance). These tasks can be done because ssh private key *id_rsa.pem* is provided in *run_ansible.sh* when running ansible command. The command also records the host key so that don't need to say yes to allow fingerprints

## Configure Application

`conf.toml.tpl` : configures *conf.toml* with necessary database configurations (E.g. correct database endpoint and credentials) in the remote server through variables in the *playbook.yml*. These details are automatically fed in through template variables obtaining database configurations through host variables in *inventory.yml* where host variables obtain information through terraform output

`playbook.yml` : After configuration of database details and seeding data into the tables, application is set as a service using SystemD so it will automatically start if the server is rebooted

**Service Explanation:**
1. Release files are moved to etc/app because service file's working directory is within the root. This enables service to start the app in correct listenport and listenhost which is configured in conf.toml
2. Service file is copied to within root so SystemD can start service. The file executes TechTestApp serve to start the server in correct directory with correct listenport and listenhost. Listenport is 80 because security group allows port 80 HTTP connections through for the application. Listenhost is 0.0.0.0 because security group HTTP connections is configured with CIDR block of 0.0.0.0/0
