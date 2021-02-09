# Analyse Problem

Servian TechChallengeApp is deployed on AWS using a simple 3 tier architecture - Load Balancer, EC2 Instance, Aurora Postgres Serverless DB. But, main issue is the manual loops & holes as highlighted below:

1. Cloud infrastructure is built, destroyed, edited & experimented manually through ClickOps - (Error-prone and time-consuming process of having to click-through various menu options in cloud provider's website, to select and configure the correct infra)
2. Manual application deployment into cloud environment
3. Manual configuration management of cloud infrastructure, environments & application itself

**Application Documentation:** https://github.com/servian/TechChallengeApp/tree/master/doc

## Problem Consequences

- Manual deployments have longer deployment time which makes it harder to perform experimentation as deploying experimentations manually will be more expensive and slower
- Longer deployment time is also due to requiring more steps for adding and removing resources. This makes it harder to reuse patterns across multiple applications
- Higher cost in terms of time & money as there are more roadblocks to reduce cloud resources when there is little traffic during non peak hours for production environment. Likewise, re-create them again, plus adding more resources to tackle spiky traffic during peak hours. *(Netflix example: many customers after working hours and few customers during non peak hours so save cost by running less servers during non peak hours and tackle customer dissatisfaction by adding additional resources during slow traffic due to high number of users)*. In addition, test environment don't need cloud infrastructure deployed outside business hours so have to destroy & stand them up again the subsequent day which doing them manually is tiresome 
- Manual deployment issues require a larger workforce to work on them because of the characteristics stated above, increasing likelihood that human errors will occur

# Solution 

A section in DevOps is **Continuous Deployment** which is the process of continuously releasing new versions of application and infrastructure to customers by iteratively improving upon the solution. This does not have to be automatic to be called CD, but aim is to automate as much as possible to help resolve problems 

Difference between CI & CD is that CI is targeting **Software Development** while CD is targeting **Software Deployment**. CI is aiming to provide developers with a fast feedback cycle on their changes in very small iterations by running this on every commit on every branch. CD is aiming to deploy completed changes to customer facing applications to add additional features or fix issues which snuck in previously  

## Why Continuous Deployment (CD)?

A CD pipeline under `.circleci` is implemented to automatically scaffold the cloud infrastructure, retrieve the latest release from application's GIT repository and deploy it into an EC2 instance as a fully configured, operational & restartable service. Required database configuration is automatically generated for db connections. The database is migrated and seeded within the automated CD process

### Cloud Infrastructure Overview (AWS & Terraform)

Choice of AWS is due to personal preference not due to AWS being better than another cloud platform. When it comes to choosing a cloud platform, 3 factors which make this decision are people, culture and skill choice (what platform the cross functional team is proficient in)

Cloud infrastructure is written as Infrastructure as Code (IaC), using a cloud agnostic language, HashiCorp Configuration Language (HCL), which is executed using HashiCorp Terraform CLI tool. The purpose of IaC is to manage state of the deployed resources by tracking or reverting any configuration drift in the environment. This ensures test and production are close as they can be so that deployment to production has less risk of issues popping up

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

IaC files are located in the `infra` folder which contains IaC required to host, access and run the application on the cloud. By default terraform uses a local backend, a remote backend setup in sub-directory, `remote-state-backend` is for managing cloud infra state. State is maintained remotely utilising an s3 bucket, storing the terraform state file and a dynamoDB table, locking the state file when terraform operations are simultaneously being performed

*State file is where terraform maps all deployed resources and state of those resources to the logical resources defined in HCL.* By locking the state file, it ensures that only 1 terraform source can apply changes to the cloud infrastructure at any one point in time, protecting against corrupted / mismatched versions of cloud infra

*deployinfra.sh* under `infra` exports newly created public key from *~/.ssh/ServianSSHKeyPair.pub* to terraform public key variable when deployment is done locally. This ensures that the public key is set as it is required when running terraform commands as the variable in `variables.tf` has no default value. Value of terraform variables can be provided in different ways but in this case, method used is through environment variables starting with **TF_VAR_**. 

If deployment is done through pipeline, variable is preconfigured in CircleCI setup. Therefore, the script enables cloud infrastructure to be deployed from a local machine and in the pipeline with the same script command

*destroyinfra.sh* under `infra` utilises the same concept as *deployinfra.sh* but for tearing down all infrastructure except for the remote backend storing the state

*makefiles* standardise and simplify terraform commands which speeds up the process of running the commands

*.gitignore* under `infra` & `remote-state-backend` folder prevents terraform cache directory and different state files from being pushed to source control

Full documentation of terraform folder is inside `infra` folder as `README`

## ansible

As EC2 is using a base linux-2 image, so once the IaC has successfully scaffolded, the server is configured with the application and it's associated configuration

A SSH public and private key pair must be generated for connecting securely into the ec2 instance. Public key is set so that it can be attached to the EC2 instance for secure SSH communication while private key is used for final communication as shown below through local terminal for debugging purposes
- ssh -i ~/.ssh/ServianSSHKeyPair ec2-user@ipaddress

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

**SSH KEY:** pair is created through `sudo sh generate-sshkey.sh` from the root directory of the repository

**AWS CREDENTIALS:** required to apply terraform scripts to scaffold aws resources.
*~/.aws/credentials* stores AWS credentials copied from your security credentials in AWS management console. Terraform can automatically search for saved API credentials so there is no need to explitly define them in .tf files. This protects the credentials when the files are checked into github

**CREATE REMOTE BACKEND:** by first entering the right directory `cd infra/remote-state-backend` and initialising terraform `make init`. To create s3 bucket & dynamoDB table for application's infra state to be stored in & access controlled by AWS IAM, run `make check` followed by `make up` 

## Pipeline Setup

Ensure **SSH KEY:** step from local setup is completed prior to attempting pipeline setup. Tool used for CD of infrastructure and application is CircleCI which uses the pipeline configured under `.circleci/config.yml`. The pipeline has been configured to only run on the master branch of the git repository

As the pipeline is adding resources inside AWS, as well as SSH'ing into running EC2 instance, AWS credentials and SSH key pair must be set up as CircleCI global environment variables for the pipeline to execute. To do so, make sure CircleCI project is linked with the git repository before attempting the following steps:
1. Click on the project settings button followed by selecting environment variables section
2. Add an environment variable for each of the fields in the AWS credentials obtained from your security credentials in AWS management console. Ensure the variable names are all capitals and values are all a single line of text
3. Run the command `cat ~/.ssh/ServianSSHKeyPair.pub | pbcopy` which outputs contents of the file & pbcopy copies it. Add an environment variable called *TF_VAR_public_key* and paste the output into the value field of the variable
4. Select SSH Keys section of the project settings menu and repeat the same command in step 3 but with `~/.ssh/ServianSSHKeyPair`. Click on Add SSH Key button, paste the output into the private key field and leave the hostname blank so that the key is used for all hosts

Pipeline is ready to commit *config.yml* to the master branch, automatically initiating it

# Deploy Instructions
## Local Deploy
Ensure all steps in local dependencies & local setup are completed prior to attempting local deployment 

To deploy app locally:
- change current directory to within infra folder
- make init (connection to the remote backend setup earlier must be established)
- make up (scaffold all AWS resources required to run the application)
- change current directory to within ansible folder
- sh run_ansible.sh (once this is done, change back to infra folder)
- make albendpoint & paste it into a browser to see a fully configured & operational application (there might be a delay response from aurora serverless db)

## Pipeline Deploy
Ensure **CREATE REMOTE BACKEND:** step from local setup is completed and all steps in pipeline setup are completed prior to attempting pipeline deployment

To deploy app automatically: 
- push into a feature branch & merge pull request to trigger the master branch or manually trigger the pipeline build in CircleCI
- when the pipeline completes scaffold-infra job, note down alb_endpoint in the CircleCI output of *Terraform apply* task 
- once the pipeline has finished, paste alb_endpoint noted down earlier into a browser to see a fully configured & operational application

# Cleanup Instructions

To destroy the application and associated cloud infra:
- change current directory to within infra folder
- make down

Once application's infra is successfully destroyed, remote backend must be manually destroyed as it is protected. To remove remote backend configuration:
- Head to AWS s3 Management Console, navigate to tf-state-s3654762-bucket
- Select list versions, select all and click delete
- Proceed to delete the s3 bucket as terraform state files have been deleted
- Head to dynamoDB tables and delete tf-state-lock-dynamodb (lock table)


