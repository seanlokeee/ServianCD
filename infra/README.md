# Documentation of Infra Folder

Terraform works out dependencies between blocks and deploy resources in correct order, so information is available for subsequent blocks

## Plugins

`main.tf` : providers are plugins for terraform using agnostic HCL language to interact with specific vendor APIs like AWS Cloud API

## Variables

`variables.tf` : easy to lookup where things are, preventing scenario where there is difficulty to find variables when they are distributed all over the files

## Outputs

`outputs.tf` : pass required information to inventory.yml file (E.g. database configuration) for configuration of application and allow these information from commmand line

## Networking Infrastructure

`vpc.tf` : VPC is created using Terraform to host application with 3 layers (Public, Private and Data) across 3 availability zones, amounting to 9 subnets. Internet gateway with route table is implemented to manage all traffic in and out of the network, requiring routing rules for it to work

**Purpose:** 
1. VPC acts as a boundary box of a home network. Thus, it is the boundary defining the cloud environment. It is everything behind a WIFI router, connected to internet connection in a home network. Thus, services are deployed within VPC
2. Division of 3 layers is for security purposes so it prevents a scenario where if someone is able to break in to access the public section, the person is unable to access database layer
3. Each AWS region is divided into availability zones like data centres that allows services to be placed. This helps spread the workload and ensure application still runs even if AWS is to lose a zone
4. Subnets further divide up assigned CIDR range, giving fine grained control over which services will be publicly available and which ones won't (E.g. where services are hosted and what users can access by default)
5. Routing rules define how traffic is directed inside subnet and VPC (E.g. any servers in private subnet trying to access internet will be directed to a NAT gateway or proxy because NAT gateway, deployed into a subnet with public internet access allows services without public IP to access internet)

## 3 Layer Infrastructure

`sg.tf` : Each layer has security groups defined to limit access, acting as firewalls. Security group is used as a software defined firewall for each individual to define which connections are allowed in and on which ports (ingress), as well as outgoing (egress). So that, infrastructure is configured for restricted access, only allowing explicit connections by denying unpermitted access

### Load Balancer (Public Layer)

`alb.tf` : Since multiple virtual machines (instances that exist in the cluster) are present, a load balancer is deployed in public layer to route traffic in either of these machines. AWS load balancer sit and move across all 3 availability zones based on an algorithm that AWS uses. Therefore, no need to deploy 3 load balancers and don't need to figure out whether have a single point of failure within the architecture

**Purpose:**
- ALB is used because it is designed for web apps and is limited to HTTP and HTTPS connections. It can also be used to set up routing rules based on HTTP request by inspecting packets and cookies which are sent through
- Load balancer uses an active health check to keep track of which instances are healthy and ready to receive requests. ALB supports HTTP and HTTPs endpoints for healthcheck so it tracks health of the instance by looking at the returned HTTP code when it is connected to the instance on a path. For example, if error code returned is 200, the server is fine while if it is 500, there is something wrong with the server
- There is a passive health check where load balancer monitor traffic by responses coming back from target instances based on user request. This allows load balancer to react to changes in state of service faster than configured active check cycle. If the instance is found unhealthy, it will be removed from pool of servers receiving traffic and if there is sufficient time, it might delete the server and stand up a new one, introducing self-healing concept

### EC2 Instance (Private Layer)

`ec2.tf` : An EC2 instance deployed in private layer using latest Amazon Linux image. EC2 instance is backed by elastic block storage (EBS) to provide storage for virtual machine and allow customization through payment for larger storage. To logon to the instance after deployment, key-pairs are used

**Purpose:**
- Build application and once inside the ami, take a snapshot of the virtual machine to allow deployment of multiple applications
- This moves towards idea of immutable hardware and servers where you care less what the servers are and if something breaks, just delete it and obtain a new one that fixes the issue
- This moves towards self healing environment where if there's an issue in the environment, delete what caused the issue and it comes back up in a clean state that fixes the issue
- Don't have to get up 3am-4am to resolve why server is not acting the way it should be as the server gets deleted, logs are reviewed in a more appropriate time. Hence, this provides a nicer experience for operations and dev teams

### Database (Data Layer)

`db.tf` : A database is deployed in data layer as a relational database service. It is a managed database service where AWS runs and maintains underlying hosts while running database on top of the instances

**Purpose:**
- Able to create new databases and manage them individually because have full control over what users can access to
- Low difficulty of managing databases as half of the job of managing has been taken care of. In addition, RDS snapshots the database so have backups available if something happens