# Analyse Problem

Servian TechChallengeApp is deployed on AWS using a simple 3 tier architecture - Load Balancer, EC2 Instance, Aurora Postgres Serverless DB. But, main issue is the manual loops & holes as highlighted below:

1. Cloud infrastructure is built, destroyed, edited & experimented manually through ClickOps - (Error-prone and time-consuming process of having to click-through various menu options in cloud provider's website, to select and configure the correct infrastructure)
2. Manual application deployment into cloud environment 
3. Manual configuration management of cloud infrastructure, environments & application itself

**Application Documentation:** https://github.com/servian/TechChallengeApp/tree/master/doc

## Problem Consequences

- Manual deployments have longer deployment time which makes it harder to perform experimentation as deploying experimentations manually will be more expensive and slower
- Longer deployment time is also due to requiring more steps for adding and removing resources. This makes it harder to reuse patterns across multiple applications
- Higher cost in terms of time & money as there are more roadblocks to reduce cloud resources when there is little traffic during non peak hours for production environment. Likewise, re-create them again, plus adding more resources to tackle spiky traffic during peak hours. (Netflix example: many customers after working hours and few customers during non peak hours, hence save cost by running less servers during non peak hours and tackle customer disatissfaction by additional resources during slow traffice due to high number of users). In addition, test environment don't need cloud infrastructure deployed outside business hours so have to destroy & stand them up again the subsequent day which doing them manually is tiresome 
- Manual deployment issues require a larger workforce to work on them because of the characteristics stated above, increasing likelihood that human errors will occur

# Solution 

A section in DevOps is **Continuous Deployment** which is the process of continuously releasing new versions of application and infrastructure to customers by iteratively improving upon the solution. This does not have to be automatic to be called CD, but aim is to automate as much as possible to help resolve problems. 

Difference between CI & CD is that CI is targeting *software development* while CD is targeting *software deployment*. CI is aiming to provide developers with a fast feedback cycle on their changes in very small iterations by running this on every commit on every branch. CD is aiming to deploy completed changes to customers facing applications to add additional features, or fix issues which snuck in previously  

## Why Continuous Deployment (CD)?

CD pipeline is implemented to automatically build cloud infrastructure so that can deploy latest release retrieved from application's GIT repository and configure it as a restartable service on an EC2 instance with required database configuration automatically generated. Database configuration is required for database connections because the database is migrated and seeded within the automated CD process

### Cloud Infrastructure Overview (AWS & Terraform)

Choice of AWS is due to personal preference not due to AWS being better than another cloud platform. When it comes to choosing a cloud platform, 3 factors which make this decision are people, culture and skill choice (what platform the cross functional team is proficient in)

Cloud infrastructure is written as Infrastructure as Code (IaC), using a cloud agnostic language, HashiCorp Configuration Language (HCL), which is executed using HashiCorp Terraform CLI tool. The purpose of IaC is to manage state of the deployed resources by tracking or reverting any configuration drift in the environment. This ensures test and production are close as they can be so that deployment to production has less risk of issues popping up

**Advantageous Scenarios:**
- By deploying and destroying infrastructure using code, predefined patterns can be created to stand up the application infrastructure and stamp out new environments on demand in a short timespan
- Ease to deploy infrastructure on different cloud providers with all same tools because only cloud specific configuration alterations are required

### Configuration Management Overview (Ansible)

Configuration is how to make the application do and behave differently in different environments. Configuration management is about how to manage configuration of environments and applications deployed in those environments. Some configuration is application specific, other configuration is for the server that the application is deployed on

To define configuration of a server using code, following one of the principles of DevOps *everything as code*, ansible is used. Helping manage large fleets of servers, ansible uses a playbook containing all tasks to be executed on the servers and an inventory containing details on the servers to manage connections

**Advantageous Scenarios:**
- Easy to add and change configuration of servers (E.g. If need to add a new server, provision it, run configuration code across it and it's ready)
- Can run same code in development, test and production as code can be ran many times over. This allows to test that everything works before going to production with the changes and also, making sure that test environment is configured the same way as production

# Briefing Before Setup
## infra

IaC files are located in the `infra` folder which contains IaC required to host, access and run the application on the cloud. By default terraform uses a local backend, remote backend setup for storing cloud infrastructure state is in sub-directory, `remote-state-backend`. The state is maintained remotely utilising an s3 bucket, used to store terraform state file so that it is accessible by CI/CD pipeline and a dynamodb table, used to lock the state file when terraform operations are being performed

*State file is where terraform maps all deployed resources and state of those resources to the logical resources defined in HCL.* By locking statefile, it ensures that only 1 terraform source can apply changes to cloud infrastructure at any one point in time, protecting against corrupted / mismatched versions of cloud infrastructure

*.gitignore* under `infra` folder contains some terraform code to prevent user from accidentally checking in the terraform cache directory and different state files

*Makefiles* standardise and simplify terraform commands which speeds up the process of running terraform commands

Full documentation of terraform folder is inside `infra` folder as `README`

## ansible

As EC2 is using a base linux-2 image so once the IaC has successfully built the cloud infrastructure, the server requires configuring with the application and it's associated configuration. In `ansible` folder, the files are used for provisioning, configuration management and application deployment 

A SSH public and private key pair must be generated for connecting securely into the ec2 instance from the local terminal. *~/.ssh/id_rsa.pem* as an example stores private key. Use command below to access EC2 Instance for debugging purposes
- ssh -i ~/.ssh/filename.pem ec2-user@ipaddress

*.keep* under `templates` is empty file hidden from view acting as convention around git implying an empty folder must be kept. This is because git doesn't know what is a folder but only knows what a file is. 

*.gitignore* under `ansible` folder prevents inventory.yml from being pushed to source control

Full documentation of ansible folder is inside `ansible` folder as `README`

# Initial Setup
## Local Dependencies

Although deployment process is fully automated, some initial setup is required before running the pipeline:
- To set up base configuration for the pipeline and enable local terraform commands, terraform CLI must be installed
- Make is required to execute Makefile commands
- Installing ansible to command line to run ansible commands as well as jq. jq is a lightweight and flexible command-line JSON processor used in ansible/run_ansible.sh script to extract the ec2 host ip address

## Local Setup

**SSH KEY:** pair used to access github in the local machine can be reuse so start by creating a new file `touch terraform.tfvars` in infra folder to import existing public key into terraform public key variable. Copy content of *~/.ssh/id_rsa.pub* and place it in the file `public_key = "?"`, making sure there is no new-line in the key

**AWS CREDENTIALS:** required to apply terraform scripts to scaffold aws resources.
*~/.aws/credentials* stores AWS credentials copied from your security credentials in AWS management console. Terraform can automatically search for saved API credentials so there is no need to explitly define them in .tf files. This protects the credentials when the files are checked into github

**CREATE REMOTE BACKEND:** by first entering the right directory `cd infra/remote-state-backend` and initialising terraform `make init`. To create s3 bucket & dynamoDB table for application's infra state to be stored in & access controlled by AWS IAM, run `make check` followed by `make up` 

# Deploy Instructions
## Local Deploy
Ensure all steps in initial setup are completed prior to attempting local deployment

To deploy app manually from a local unix terminal:
- cd infra
- make init (remote backend has already been constructed in initial setup. The connection to the remote backend must be established)
- make check (validate, format code & outline differences between the 2 states)
- make up (scaffold all AWS resources required to run the application)
- cd .. (note down terraform output alb_endpoint value or make albendpoint)
- cd ansible
- sh run_ansible.sh
- Paste alb_endpoint noted down earlier into a browser to see application

# Cleanup Instructions

To clean up the application's cloud infra:
- cd infra
- make down

Once application's infra is successfully destroyed, remote backend must be manually destroyed as it is protected. To remove remote backend configuration:
- Head to AWS s3 Management Console, navigate to tf-state-s3654762-bucket
- Select list versions, select all and click delete
- Proceed to delete the s3 bucket as terraform state files have been deleted
- Head to dynamoDB tables and delete tf-state-lock-dynamodb (lock table)


