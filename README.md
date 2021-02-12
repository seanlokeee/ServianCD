# Analyse Problem

Servian TechChallengeApp is deployed on AWS using a simple 3 tier architecture - Load Balancer, EC2 Instance, Aurora Postgres Serverless DB. But, main issue is the manual loops & holes as highlighted below:

1. Cloud infrastructure is built, destroyed, edited & experimented manually through ClickOps - (Error-prone and time-consuming process of having to click-through various menu options in cloud provider's website, to select and configure the correct infra)
2. Manual application deployment into cloud environment
3. Manual configuration management of cloud infrastructure, environments & application itself

**Application Documentation:** https://github.com/servian/TechChallengeApp/tree/master/doc

## Problem Consequences

- Manual deployments have longer deployment time which makes it harder to perform experimentation as deploying experimentations manually will be more expensive and slower
- Longer deployment time is also due to requiring more steps for adding and removing resources. This makes it harder to reuse patterns across multiple applications
- Higher cost in terms of time & money as there are more roadblocks to reduce cloud resources when there is little traffic during non peak hours for production environment. Likewise, re-create them again, plus adding more resources to tackle spiky traffic during peak hours. **(Netflix example: many customers after working hours and few customers during non peak hours so save cost by running less servers during non peak hours and tackle customer dissatisfaction by adding additional resources during slow traffic due to high number of users)**. In addition, test environment don't need cloud infrastructure deployed outside business hours so have to destroy & stand them up again the subsequent day which doing them manually is tiresome 
- Manual deployment issues require a larger workforce to work on them because of the characteristics stated above, increasing likelihood that human errors will occur

# Solution 

A section in DevOps is **Continuous Deployment** which is the process of continuously releasing new versions of application and infrastructure to customers by iteratively improving upon the solution. This does not have to be automatic to be called CD, but aim is to automate as much as possible to help resolve problems 

Difference between CI & CD is that CI is targeting **Software Development** while CD is targeting **Software Deployment**. CI is aiming to provide developers with a fast feedback cycle on their changes in very small iterations by running this on every commit on every branch. CD is aiming to deploy completed changes to customer facing applications to add additional features or fix issues which snuck in previously  

## Why Continuous Deployment (CD)?

A CD pipeline under `.circleci` is implemented to automatically scaffold the cloud infrastructure, retrieve the latest release from application's GIT repository and deploy it into an EC2 instance as a fully configured, operational & restartable service. Required database configuration is automatically generated for db connections. The database is migrated and seeded within the automated CD process

### Cloud Infrastructure Overview (AWS & Terraform)

Choice of AWS is due to personal preference not due to AWS being better than another cloud platform. When it comes to choosing a cloud platform, 3 factors which make this decision are people, culture and skill choice (what platform the cross functional team is proficient in)

Cloud infra is written as Infrastructure as Code (IaC), using a cloud agnostic language, HashiCorp Configuration Language (HCL), which is executed using HashiCorp Terraform CLI tool. The purpose of IaC is to manage state of the deployed resources by tracking or reverting any configuration drift in the environment. This ensures test and production are close as they can be so that deployment to production has less risk of issues popping up

**Advantageous Scenarios:**
- By deploying and destroying infrastructure using code, predefined patterns can be created to stand up the application infra and stamp out new environments on demand in a short timespan
- Ease to deploy infrastructure on different cloud providers with all the same tools because only cloud specific configuration alterations are required

### Configuration Management Overview (Ansible)

Configuration is how to make the application do and behave differently in different environments. Configuration management is about how to manage config of environments and applications deployed in those environments. Some configuration is application specific, other config is for the server that the application is deployed on

To define configuration of a server using code, following one of the principles of DevOps **Everything As Code**, ansible is used. Helping manage large fleets of servers, ansible uses a playbook containing all tasks to be executed on the servers and an inventory containing details on the servers to manage connections

**Advantageous Scenarios:**
- Easy to add and change configuration of servers (E.g. If need to add a new server, provision it, run config code across it and it's ready)
- Can run same code in development, test and production as code can be ran many times over. This allows to test that everything works before going to production with the changes and also, making sure that test environment is configured the same way as production

# Briefing Before Setup
## infra

IaC files are located in `infra` folder which contains IaC required to host, access and run the application on the cloud. Terraform keeps track of environment changes by creating `terraform.tfstate` in local filesystem. Whenever terraform plan, apply or destroy command runs, it reads the current state from `terraform.tfstate` and applies changes to it. The specified file is called a **state file** acting as a small database storing environment state. **State file is where terraform maps all deployed resources and state of those resources to the logical resources defined in HCL**  

`remote-backend-infra` deploys s3 bucket & dynamoDB to manage state file remotely, ensuring accessibility via CD pipeline. Remote backend connection to utilise s3 & dynamoDB is configured in `main.tf`. With remote backend connection established, terraform automatically pulls latest state from s3 bucket before running one of the commands stated above, and automatically push the latest state to the bucket after running the command

**deployinfra.sh** under `infra` exports newly created public key from **~/.ssh/ServianSSHKeyPair.pub** to public key variable in `variables.tf` if deployment is done locally. This ensures that the terraform public key is set as it is required when running terraform commands due to the variable having no default value

Value of terraform variables can be provided in different ways but method used here is through environment variables starting with **TF_VAR_** . If deployment is done through pipeline, variable is preconfigured in CircleCI setup

**destroyinfra.sh** under `infra` utilises the same concept as `deployinfra.sh` but for tearing down all infrastructure except for the remote backend storing the state. Therefore, both scripts enable cloud infra to be deployed & destroyed from a local machine and in the pipeline with the same script command

**makefiles** standardise and simplify terraform commands which speeds up the process of running the commands

**.gitignore** under `infra` & `remote-backend-infra` folder prevents terraform cache directory and different state files from being pushed to source control

Full documentation of terraform folder is inside `infra` folder as `README`

## ansible

As EC2 is using a base linux-2 image, so once the IaC has successfully scaffolded, the server is configured with the application and it's associated configuration

A SSH public and private key pair must be generated for connecting securely into the ec2 instance. Public key is set so that it can be attached to the EC2 instance for secure SSH communication while private key is used for final communication as shown below through local terminal for debugging purposes
- ssh -i ~/.ssh/ServianSSHKeyPair ec2-user@ipaddress

**.keep** under `templates` is empty file hidden from view acting as convention around git implying an empty folder must be kept. This is because git doesn't know what is a folder but only knows what a file is. 

**.gitignore** under `ansible` folder prevents inventory.yml from being pushed to source control

Full documentation of ansible folder is inside `ansible` folder as `README`

# Initial Setup
## Local Dependencies

Although deployment process is fully automated, some initial setup is required before running the pipeline:
- To set up base configuration for the pipeline and enable local terraform commands, terraform CLI must be installed. Make sure the local terraform version is newer or the same version as the CircleCI image terraform version.
- Make is required to execute Makefile commands
- Installing ansible to command line to run ansible commands as well as jq. jq is a lightweight and flexible command-line JSON processor used in ansible/run_ansible.sh script to extract the ec2 host ip address

## Local Setup

**SSH KEY:** pair is created by `sudo sh generate-sshkey.sh` from root directory of repository. `sudo` allows overwriting of existing key pair due to superuser's permission 

**AWS CREDENTIALS:** required to apply terraform scripts to scaffold aws resources.
**~/.aws/credentials** stores AWS credentials copied from your security credentials in AWS management console. Terraform can automatically search for saved API credentials so there is no need to explitly define them in .tf files. This protects the credentials when the files are checked into github

**REMOTE BACKEND INFRA:** is built before defining it's remote connection. Thus, the infra is created in a separate folder than the main infra because `main.tf` contains the remote backend connection which enables remote storage of the main infra terraform state file
1. `cd infra/remote-backend-infra`  
2. `make init` - defining local terraform state file for creating s3 & dynamoDB
3. `make check` followed by `make up` (validate, format, plan -> apply)

## Pipeline Setup

Ensure **SSH KEY** step from local setup is completed prior to attempting pipeline setup. Tool used for CD of infrastructure and application is CircleCI which uses the pipeline configured under `.circleci/config.yml`

As the pipeline is adding resources inside AWS, as well as SSH'ing into running EC2 instance, AWS credentials and SSH key pair must be set up as CircleCI global environment variables for the pipeline to execute. To do so, make sure CircleCI project is linked with the git repository before attempting the following steps:
1. Click on the project settings button followed by selecting environment variables section
2. Add environment variables for the fields in AWS credentials obtained from your security credentials in AWS management console. Ensure the variable names are all capitals and values are all a single line of text
3. `cat ~/.ssh/ServianSSHKeyPair.pub | pbcopy` outputs file's contents & copies them. Add an environment variable, **TF_VAR_public_key**, paste the output into the value field
4. Select SSH Keys section of project settings menu and repeat the same command in step 3 but with `~/.ssh/ServianSSHKeyPair`. Add SSH Key, paste the output into the private key field and leave the hostname blank so that the key is used for all hosts

Pipeline is ready to commit `config.yml` to the master branch, automatically initiating it

# Deploy Instructions
## Local Deploy
Ensure all steps in local dependencies & local setup are completed prior to attempting local deployment 

To see a fully configured & operational application on AWS through local terminal:
- change current directory to within infra folder
- make init (connection to the remote backend built in local setup is established here)
- make up (scaffold all AWS resources required to run the application)
- change current directory to within ansible folder
- sh run_ansible.sh (once this is done, change back to infra folder)
- make albendpoint & paste it into a browser (delayed response from aurora db might arise)

## Pipeline Deploy
Ensure **REMOTE BACKEND INFRA** step from local setup is completed and all steps in pipeline setup are completed prior to attempting pipeline deployment

To see a fully configured & operational application on AWS through CircleCI CD Pipeline:
- push into a branch & merge pull request to trigger the master branch or manually trigger the pipeline build in CircleCI (local terraform version must be newer than image version)
- when the pipeline completes scaffold-infra job, note down alb_endpoint in CircleCI output
- once the pipeline has finished, paste alb_endpoint noted down earlier into a browser

# Cleanup Instructions

To destroy the application and associated cloud infra:
- change current directory to within infra folder & make init to access remote state file
- if Error: Invalid legacy provider address, terraform state replace-provider -- -/aws hashicorp/aws to update provider in state file by upgrading the syntax. Re-run make init
- make down (able to delete infra locally now because local is connected to remote backend)

Remote backend must be manually destroyed as it is protected:
- Head to AWS s3 Management Console, navigate to tf-state-s3654762-bucket
- Select list versions, select all and click delete
- Proceed to delete the s3 bucket as terraform state files have been deleted
- Head to dynamoDB tables and delete tf-state-lock-dynamodb (lock table)


