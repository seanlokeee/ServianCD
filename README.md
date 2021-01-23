# Analyse Problem

A customer web application using Golang is created. But issue with current application deployment is that it has been manual using ClickOps (Error-prone and time-consuming process of having to click-through various menu options in cloud provider's website, to select and configure the correct infrastructure) and manual configuration management of infrastructure and application itself.

**Application Documentation:** https://github.com/servian/TechChallengeApp/tree/master/doc

## Problem Consequences

- Manual deployments have longer deployment time which makes it harder to perform experimentation as deploying experimentations manually will be more expensive and slower
- Longer deployment time is also due to requiring more steps for adding and removing resources, hence making it more difficult to do so
- This makes it harder to reuse patterns across multiple applications
- Therefore, manual deployment issues require a larger workforce to work on them because of the characteristics stated above, increasing the likelihood that human errors will occur

# Solution 

One of the sections of DevOps is **Continuous Deployment** which is the process of continuously releasing new versions of application and infrastructure to customers by iteratively improving upon the solution. This does not have to be automatic to be called CD, but aim is to automate as much as possible to help resolve the problems. The difference between CI & CD is that CI is targeting *software development* while CD is targeting *software deployment*. CI is aiming to provide developers with a fast feedback cycle on their changes in very small iterations by running this on every commit on every branch. CD is aiming to deploy completed changes to customers facing applications to add additional features, or fix issues which snuck in previously  

## Why Continuous Deployment (CD)?

CD pipeline is implemented to automatically build cloud infrastructure so that can deploy the latest release retrieved from the application's GIT repository and configure it as a restartable service on an EC2 instance, with required database configuration automatically generated. Database configuration are required for database connections because the database is migrated and seeded within the CD process

- By deploying and destroying infrastructure using code, predefined patterns can be created to stand up the application infrastructure and stamp out new environments on demand in a short timespan
- Changing to a different cloud provider is relatively easy compared to using ClickOps because different cloud providers are supported with all the same tools and only cloud specific configuration alterations are required

### Cloud Infrastructure Overview (AWS & Terraform)

Choice of AWS is due to personal preference not due to AWS being better than another cloud platform. When it comes to choosing a cloud platform, 3 factors which make this decision are people, culture and skill choice (what platform the cross functional team is proficient in)

Cloud infrastructure is written as Infrastructure as Code (IaC), using a cloud agnostic language, HashiCorp Configuration Language (HCL), which is executed using HashiCorp Terraform CLI tool. The purpose of IaC is to manage state of the deployed resources by tracking or reverting any configuration drift in the environment. This ensures test and production are close as they can be so that deployment to production has less risk of issues popping up

**Advantageous Scenarios:**
- Test environment don't need cloud infrastructure deployed outside business hours as able to use terraform to destroy infrastructure easily
- This also applies to spiky traffic during peak hours and little traffic during non peak hours for production environment (E.g. Netflix example: many customers after working hours and few customers during non peak hours, hence save cost by running less servers during non peak hours)
- Quicker to deploy, edit & destroy infrastructure using terraform

### Configuration Management Overview (Ansible)

Configuration is how to make the application do and behave differently in different environments. Configuration management is about how to manage configuration of environments and applications deployed in those environments. Some configuration is application specific, other configuration is for the server that the application is deployed on

To define configuration of a server using code, following one of the principles of DevOps *everything as code*, ansible is used, helping manage large fleets of servers. Ansible uses a playbook containing all tasks to be executed on the servers and an inventory containing details on the servers to manage connections

**Advantageous Scenarios:**
- Easy to add and change configuration of servers (E.g. If need to add a new server, provision it, run configuration code across it and it's ready)
- Can run same code in development, test and production as code can be ran many times over. This allows to test that everything works before going to production with the changes and also, making sure that test environment is configured the same way as production

# Terraform Setup

IaC files are located in the `infra` folder which contains IaC required to host, access and run the application on the cloud. A sub-directory, `base-infra` has configuration for set up of a remote backend for managing state of cloud infrastructure. State of cloud infrastructure will be maintained remotely utilising an s3 bucket and a dynamo db table, used to lock the state file when terraform operations are being performed

*State file is where terraform maps all deployed resources and state of those resources to the logical resources defined in HCL.* By locking statefile, it ensures that only 1 terraform source can apply changes to cloud infrastructure at any one point in time, protecting against corrupted / mismatched versions of cloud infrastructure

*.gitignore* under `infra` folder contains some terraform code to prevent user from accidentally checking in the terraform cache directory and different state files

Full documentation of terraform folder is inside `infra` folder as `README`

## AWS

*~/.aws/credentials* stores AWS credentials which are obtained through your security credentials. Terraform can automatically search for saved API credentials so there is no need to explitly define them in .tf files. This protects the credentials when the files are checked into github

## KeyPair

Key pair is used to log into the ec2 instance. As there is already an SSH key set up to access github in the machine, can reuse this key. Create a new file *touch terraform.tfvars* in `infra` folder to import existing key pair into public key variable to match with resource aws_key_pair in terraform. Copy content of *~/.ssh/id_rsa.pub* and place it in the file `public_key = "?"`, making sure there is no new-line in the key

## Makefile

Standardise and simplify terraform commands which speeds up the process of running terraform commands. Make sure to install terraform CLI to your command line in order to run the commands
- `make init` runs `terraform init`*, scan terraform files to see what modules and providers to download to make the environment ready accordingly* - `make up` runs `apply.sh`
- `make down` runs `destroy.sh`

# Ansible Setup

Configuration management EC2 is using a base linux-2 image so once the IaC has successfully built the cloud infrastructure, the server requires configuring with the application and it's own configuration. Make sure to install ansible to command line in order to run ansible commands

Ansible playbook handles download of latest release file from github by sshing through the ec2 instance and place it in the instance. The playbook also handles running of application through a service file. Alongside terraform, both work together to get the correct database configuration through

*.gitignore* under `ansible` folder prevents inventory.yml from being pushed to source control

*.keep* under `templates` is empty file hidden from view acting as  convention around git implying `templates` folder is to be kept. Because,
git doesn't know what is a folder but it only knows what a file is

Full documentation of ansible folder is inside `ansible` folder as `README`

## SSH

*~/.ssh/id_rsa.pem* stores SSH private key for SSH connection to EC2 instance. Make sure file is in a .pem format.

Use command below to access EC2 Instance for debugging purposes
*ssh -i ~/.ssh/filename.pem ec2-user@ipaddress*

# Deploy Instructions
- cd infra
- make init (local state)
- make check
- make up
- cd ..
- cd ansible
- sh run_ansible.sh
- Copy the IP address to the web browser to see application deployed

# Cleanup Instructions
- make down (destroys everything as force destroy is set to true)


