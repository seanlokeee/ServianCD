# Documentation of Ansible Folder

Ansible command in `run_ansible.sh` runs `playbook.yml` against all hosts in automatically generated `inventory.yml`. Playbook defines server configuration to deploy against each host defined in inventory

## Automatically Generate Inventory File

`run_ansible.sh` : Entry point for setting configuration and deploying application. The script sets environment variables based on outputs from terraform, followed by using these variables in the generation of an inventory.yml file which provides all necessary database config to the EC2 host

The script checks if private key file exists to enable both local and CD remote pipeline application deployment within the same script 

**Ansible Command Explanation:**
- ANSIBLE_HOST_KEY_CHECKING set to false to ignore SSH authenticity checking to avoid any human intervention in middle of script execution
- record_host_keys set to false to prevent recording of newly discovered and approved hosts in the user's hostfile. This improves performance and is recommended when host key checking is disabled so that don't need to say yes to allow fingerprints

## Ensure App Directory Exists

`playbook.yml` : Service file's working directory is within the root so release zip file must be unzipped within root. This enables service to start the app with listenport and listenhost configured in **conf.toml**. Therefore, checking whether directory exists gives a safety measure where if it doesn't exist, the task fails, preventing consequent tasks from running

## Download Application and Copy to Local Drive

`playbook.yml` : Downloads application zip file from github and unzip in remote server (EC2 instance), where release files are placed in **/etc/app/**. This prevents the need of copying application from local machine to ec2 instance

## Configure Application

`conf.toml.tpl` : Updates one of the unarchived files, **conf.toml** with necessary database config in the remote server to suit the cloud infrastructure through variables in the playbook. Playbook variables' data are automatically fed in through host variables in **inventory.yml** where host variables obtain information through terraform output variables configured in **output.tf**

## Configure Service

`playbook.yml` : After configuration of database details, application is set as a service using SystemD so it will automatically start if the server is rebooted. To do that, a predefined service file, **servian.service** is copied to within root so that it executes **TechChallengeApp serve** starting the server only in the configured directory with configured listenport and listenhost. Listenport is 80 because security group allows port 80 HTTP connections through for the application. Listenhost is 0.0.0.0 because security group HTTP connections is configured with CIDR block of 0.0.0.0/0

## Configure Database 

`playbook.yml` : Finally, the last task seeds data into newly created tables without creating a new database as it already exists
